# A monthly budget on this resource group. It sends email.
# It does not stop spending. The address comes from
# TF_VAR_budget_alert_email and is not written in this file.
# Azure requires the start date to be the first day of a month.
# This budget starts on the first day of the current month.

resource "azurerm_consumption_budget_resource_group" "monthly" {
  name              = var.budget_name
  resource_group_id = azurerm_resource_group.rg.id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-10-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = var.budget_actual_percent
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.budget_alert_email]
  }

  notification {
    enabled        = true
    threshold      = var.budget_forecast_percent
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"
    contact_emails = [var.budget_alert_email]
  }
}
