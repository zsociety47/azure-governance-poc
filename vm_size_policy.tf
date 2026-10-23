# Denies a virtual machine whose size is not on the allow list.
# The built-in policy effect is Deny. enforce = true means Azure
# applies that effect instead of only recording it.
# Scope is this resource group. No virtual machine is created here.
# The later test tries Standard_F16als_v7, which is not in the list.

resource "azurerm_resource_group_policy_assignment" "vm_sizes" {
  name                 = var.policy_assignment_name
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = var.policy_definition_id
  description          = "Only the two small sizes on the allow list may be created in this group."
  enforce              = true

  parameters = jsonencode({
    listOfAllowedSKUs = {
      value = var.allowed_vm_sizes
    }
  })
}
