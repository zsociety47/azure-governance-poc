#!/bin/bash
# Reads the live governance controls and prints a pass/fail table.
# Inputs: an Azure command-line interface (CLI) login, plus .env in this
# folder for the Terraform plan. The subscription id is not printed.
# Output: nine lines, each PASS or FAIL. Exit 0 when all pass, exit 1 otherwise.
# Side effects: none. The size checks ask policy what it would do. They
# do not create a virtual machine. terraform plan does not apply.

set -u
set -o pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

resource_group="rg-gov-poc-zeon01"
location="eastus"
user_display="Junior Developer"
mail_nickname="junior-dev-zeon"
policy_name="restrict-vm-sizes"
allowed_sizes="Standard_F1als_v7 Standard_F1as_v7"
denied_size="Standard_F16als_v7"
allowed_size="Standard_F1als_v7"
budget_name="monthly-gov-budget"

if [[ -z "${ARM_SUBSCRIPTION_ID:-}" ]]; then
  ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
  export ARM_SUBSCRIPTION_ID
fi

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

failed=0
pass() { printf '%s  %s: PASS\n' "$1" "$2"; }
fail() { printf '%s  %s: FAIL\n' "$1" "$2"; failed=1; }

scope="$(az group show --name "$resource_group" --query id -o tsv 2>/dev/null || true)"

group_location="$(az group show --name "$resource_group" --query location -o tsv 2>/dev/null || true)"
if [[ "$group_location" == "$location" ]]; then
  pass 1 "Resource group ${resource_group} is in ${location}"
else
  fail 1 "Resource group ${resource_group} is in ${location}"
fi

user_id="$(az ad user list --display-name "$user_display" --query "[0].id" -o tsv 2>/dev/null || true)"
user_facts="{}"
if [[ -n "$user_id" ]]; then
  user_facts="$(az rest --method get \
    --url "https://graph.microsoft.com/v1.0/users/${user_id}?\$select=accountEnabled,mailNickname" \
    --query "{enabled:accountEnabled, nickname:mailNickname}" \
    -o json 2>/dev/null || echo '{}')"
fi
user_ok="$(printf '%s' "$user_facts" | python3 -c '
import json, sys
facts = json.load(sys.stdin)
print("yes" if facts.get("enabled") is True and facts.get("nickname") == "junior-dev-zeon" else "no")
')"
if [[ "$user_ok" == "yes" ]]; then
  pass 2 "Test user ${user_display} is enabled"
else
  fail 2 "Test user ${user_display} is enabled"
fi

roles="[]"
if [[ -n "$scope" ]]; then
  roles="$(az role assignment list --scope "$scope" \
    --query "[].{role:roleDefinitionName, principal:principalId}" \
    -o json 2>/dev/null || echo '[]')"
fi
role_ok="$(USER_ID="$user_id" python3 -c '
import json, os, sys
rows = json.load(sys.stdin)
uid = os.environ.get("USER_ID", "")
ok = len(rows) == 1 and rows[0].get("role") == "Reader" and rows[0].get("principal") == uid and uid != ""
print("yes" if ok else "no")
' <<<"$roles")"
if [[ "$role_ok" == "yes" ]]; then
  pass 3 "Reader on ${resource_group} is only the test user"
else
  fail 3 "Reader on ${resource_group} is only the test user"
fi

policy_json="[]"
if [[ -n "$scope" ]]; then
  policy_json="$(az policy assignment list --scope "$scope" \
    --query "[?name=='${policy_name}'].{mode:enforcementMode, skus:parameters.listOfAllowedSKUs.value}" \
    -o json 2>/dev/null || echo '[]')"
fi
policy_ok="$(printf '%s' "$policy_json" | python3 -c '
import json, sys
rows = json.load(sys.stdin)
want = ["Standard_F1als_v7", "Standard_F1as_v7"]
ok = len(rows) == 1 and rows[0].get("mode") == "Default" and sorted(rows[0].get("skus") or []) == sorted(want)
print("yes" if ok else "no")
')"
if [[ "$policy_ok" == "yes" ]]; then
  pass 4 "Policy ${policy_name} allows only the two small sizes"
else
  fail 4 "Policy ${policy_name} allows only the two small sizes"
fi

budget_json="{}"
if [[ -n "$scope" ]]; then
  budget_json="$(az rest --method get \
    --url "${scope}/providers/Microsoft.Consumption/budgets/${budget_name}?api-version=2023-05-01" \
    --query "{amount:properties.amount, grain:properties.timeGrain, notes:properties.notifications}" \
    -o json 2>/dev/null || echo '{}')"
fi
budget_ok="$(printf '%s' "$budget_json" | python3 -c '
import json, sys
raw = json.load(sys.stdin)
notes = list((raw.get("notes") or {}).values())
def has(threshold, kind):
    return any(
        n.get("enabled") is True
        and n.get("operator") == "GreaterThanOrEqualTo"
        and float(n.get("threshold") or 0) == float(threshold)
        and n.get("thresholdType") == kind
        and len(n.get("contactEmails") or []) == 1
        for n in notes
    )
ok = (
    float(raw.get("amount") or 0) == 50.0
    and raw.get("grain") == "Monthly"
    and has(80, "Actual")
    and has(100, "Forecasted")
)
print("yes" if ok else "no")
')"
if [[ "$budget_ok" == "yes" ]]; then
  pass 5 "Budget ${budget_name} is 50 dollars with both alerts"
else
  fail 5 "Budget ${budget_name} is 50 dollars with both alerts"
fi

# Asks policy whether this size would be denied. The call does not create a machine.
deny_count() {
  local size="$1"
  local body
  body="$(SIZE="$size" python3 -c 'import json, os; print(json.dumps({"resourceDetails": {"apiVersion": "2024-07-01", "resourceContent": {"type": "Microsoft.Compute/virtualMachines", "location": "eastus", "properties": {"hardwareProfile": {"vmSize": os.environ["SIZE"]}}}}}))')"
  az rest --method post \
    --url "${scope}/providers/Microsoft.PolicyInsights/checkPolicyRestrictions?api-version=2024-10-01" \
    --body "$body" \
    --query "length(contentEvaluationResult.policyEvaluations[?policyInfo.policyAssignmentName=='${policy_name}' && evaluationResult=='NonCompliant' && effectDetails.policyEffect=='Deny'])" \
    -o tsv 2>/dev/null || echo "error"
}

denied_hits="$(deny_count "$denied_size")"
if [[ "$denied_hits" == "1" ]]; then
  pass 6 "Size ${denied_size} is denied by ${policy_name}"
else
  fail 6 "Size ${denied_size} is denied by ${policy_name}"
fi

allowed_hits="$(deny_count "$allowed_size")"
if [[ "$allowed_hits" == "0" ]]; then
  pass 7 "Size ${allowed_size} is not denied"
else
  fail 7 "Size ${allowed_size} is not denied"
fi

vm_count="$(az vm list --resource-group "$resource_group" --query "length(@)" -o tsv 2>/dev/null || echo "error")"
if [[ "$vm_count" == "0" ]]; then
  pass 8 "Resource group ${resource_group} has no virtual machine"
else
  fail 8 "Resource group ${resource_group} has no virtual machine"
fi

plan_log="$(mktemp)"
trap 'rm -f "$plan_log"' EXIT
set +e
terraform plan -input=false -detailed-exitcode -no-color >"$plan_log" 2>&1
plan_status=$?
set -e
if [[ "$plan_status" -eq 0 ]]; then
  pass 9 "terraform plan reports no changes"
else
  fail 9 "terraform plan reports no changes"
  sed -E \
    -e 's#/subscriptions/[0-9a-fA-F-]+#/subscriptions/<id>#g' \
    -e 's#[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}#<address>#g' \
    "$plan_log" | tail -n 20
fi

exit "$failed"
