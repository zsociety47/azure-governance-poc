# Reads the tenant's default domain. The user file will put the mail
# nickname in front of it. The domain is not written in this repository.
# This block creates nothing in Azure or in Microsoft Entra ID.
#
# only_default asks for the one domain Entra treats as the default.
# The check fails the plan if that list is not exactly one domain.

data "azuread_domains" "tenant" {
  only_default = true
}

check "one_default_domain" {
  assert {
    condition     = length(data.azuread_domains.tenant.domains) == 1
    error_message = "Expected exactly one default domain for this tenant."
  }
}
