# Signs in to Azure before any resource file runs.
# Later resource files use these providers. They do not sign in themselves.
#
# Authentication uses the Azure command-line interface (CLI) login already
# on this machine. The subscription id is read from the ARM_SUBSCRIPTION_ID
# environment variable, so it is not stored in this file. ARM is the prefix
# the Azure Resource Manager provider uses for its environment variables.
# The Entra provider reads the tenant from that same CLI login.

provider "azurerm" {
  # Do not register Azure resource providers during apply.
  # Microsoft.Authorization and Microsoft.Consumption are already
  # registered on this subscription. This project uses them for role
  # assignments, policy, and the budget.
  resource_provider_registrations = "none"

  # Required by the provider even when no feature flags are set.
  features {}
}

provider "azuread" {
}
