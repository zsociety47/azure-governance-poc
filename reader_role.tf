# Gives the test user Reader on this resource group only.
# Reader can look at resources. It cannot create, change, or delete them.
# principal_id is the user's object id. The /users path is not a principal.
# The policy and the budget are later files. They are not here.

resource "azurerm_role_assignment" "junior_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = var.role_definition_name
  principal_id         = azuread_user.junior.object_id
}
