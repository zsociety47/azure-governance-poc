# The test user in Microsoft Entra ID.
# The sign-in name is the mail nickname plus the default domain
# read by domain.tf. The password has no default. It comes from
# TF_VAR_user_password at plan and apply time, and Terraform state
# stores it. State stays gitignored.
# The role that limits this user is a later file. It is not here.
# The address list is off so this test account is not listed as a person.

resource "azuread_user" "junior" {
  user_principal_name  = "${var.user_mail_nickname}@${one(data.azuread_domains.tenant.domains).domain_name}"
  display_name         = var.user_display_name
  mail_nickname        = var.user_mail_nickname
  password             = var.user_password
  account_enabled      = true
  show_in_address_list = false
}
