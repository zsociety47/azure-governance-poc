# Names, region, and tags for this build.
# The provider is already configured. Resource files read these values
# so a name is written once and reused everywhere.
#
# The test user's password and the budget alert address have no default.
# They are supplied from the environment when a resource needs them:
# TF_VAR_user_password and TF_VAR_budget_alert_email.

variable "location" {
  description = "Azure region for every resource in this build."
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group that every governance control is scoped to."
  type        = string
  default     = "rg-gov-poc-zeon01"
}

variable "user_display_name" {
  description = "Display name of the test user in Microsoft Entra ID."
  type        = string
  default     = "Junior Developer"
}

variable "user_mail_nickname" {
  description = "Sign-in name before the @. The tenant domain is looked up later and is not stored here."
  type        = string
  default     = "junior-dev-zeon"
}

variable "user_password" {
  description = "Password for the test user. Supplied at apply time. Terraform state stores it, and state is gitignored."
  type        = string
  sensitive   = true
}

variable "role_definition_name" {
  description = "Built-in role assigned to the test user on the resource group only."
  type        = string
  default     = "Reader"
}

variable "policy_assignment_name" {
  description = "Name of the policy assignment on the resource group."
  type        = string
  default     = "restrict-vm-sizes"
}

variable "policy_definition_id" {
  description = "Built-in policy definition: Allowed virtual machine size SKUs."
  type        = string
  default     = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"
}

variable "allowed_vm_sizes" {
  description = "Virtual machine sizes the policy allows. Two 1-core sizes this subscription offers in East US."
  type        = list(string)
  default     = ["Standard_F1als_v7", "Standard_F1as_v7"]
}

variable "denied_vm_size" {
  description = "Larger size the later policy test tries. It is off the allow list. No virtual machine is created."
  type        = string
  default     = "Standard_F16als_v7"
}

variable "budget_name" {
  description = "Name of the resource group budget."
  type        = string
  default     = "monthly-gov-budget"
}

variable "budget_amount" {
  description = "Monthly budget amount in US dollars. A budget sends alerts. It does not stop spending."
  type        = number
  default     = 50
}

variable "budget_actual_percent" {
  description = "Alert when actual spend reaches this percent of the budget."
  type        = number
  default     = 80
}

variable "budget_forecast_percent" {
  description = "Alert when forecasted spend reaches this percent of the budget."
  type        = number
  default     = 100
}

variable "budget_alert_email" {
  description = "Address that receives budget alerts. Supplied at apply time. Not stored in this file."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags on the resource group."
  type        = map(string)
  default = {
    project     = "azure-governance-poc"
    environment = "poc"
    managed-by  = "terraform"
    owner       = "zeon"
  }
}
