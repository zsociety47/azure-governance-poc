# Pins the tool versions before any Azure resource is declared.
# terraform init reads this block and downloads the providers it names.
# Later resource files depend on those providers staying the same version.
#
# azurerm manages the resource group, the role assignment, the policy, and the budget.
# azuread manages the user in Microsoft Entra ID. The network project does not need it.

terraform {
  required_version = "~> 1.15.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 5.10.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "= 3.10.0"
    }
  }
}
