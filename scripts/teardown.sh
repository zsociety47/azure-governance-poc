#!/bin/bash
# Deletes this proof of concept after the resource group name is typed.
# Inputs: an Azure command-line interface (CLI) login, and .env so
# Terraform can read the password and the alert address. Those values
# are not printed.
# Output: Terraform's destroy plan, then its own yes prompt.
# Side effects: after both answers match, this deletes the resource
# group, the budget, the size policy, the Reader role, and the test
# user in Microsoft Entra ID. The user is not inside the group.
# Terraform removes the user because the user is in the state file.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

resource_group="rg-gov-poc-zeon01"

echo "This deletes:"
echo "  resource group ${resource_group}"
echo "  budget monthly-gov-budget"
echo "  policy assignment restrict-vm-sizes"
echo "  Reader role on that group"
echo "  Entra user Junior Developer"
echo
echo "Nothing is deleted until the name matches and you type yes for the destroy plan."
printf 'Type %s to continue: ' "$resource_group"
read -r typed
if [[ "$typed" != "$resource_group" ]]; then
  echo "The name did not match. Nothing was deleted."
  exit 1
fi

if [[ ! -f .env ]]; then
  echo ".env is missing. Nothing was deleted."
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

if [[ -z "${ARM_SUBSCRIPTION_ID:-}" ]]; then
  ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
  export ARM_SUBSCRIPTION_ID
fi

terraform destroy -input=false
