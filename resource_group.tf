# The container for every later control.
# The role assignment, the policy, and the budget reference this block,
# so Terraform creates the group first.

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
