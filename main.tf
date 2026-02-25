data "azurerm_client_config" "current" {}

# -----------------------------
# Resource Group
# -----------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# -----------------------------
# Module 1: Azure Monitor Workspace + Subscription Association
# Provisions the AMW, wires it to the subscription as the default workspace
# (preview API via AzAPI), and optionally grants an RBAC role.
# -----------------------------
module "amw" {
  source = "./modules/amw-subscription-association"

  amw_name             = var.amw_name
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  subscription_id      = data.azurerm_client_config.current.subscription_id
  principal_id         = data.azurerm_client_config.current.object_id
  assign_role          = var.assign_amw_role
  role_definition_name = var.amw_role_definition_name
}

# -----------------------------
# Module 2: Availability Monitoring Stack
# Provisions LAW, workspace-based App Insights, a classic ping web test,
# an action group, and a metric availability alert.
# -----------------------------
module "availability" {
  source = "./modules/availability-monitoring"

  law_name            = var.law_name
  appi_name           = var.appi_name
  webtest_name        = var.webtest_name
  action_group_name   = var.action_group_name
  alert_name          = var.alert_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  webtest_url         = var.webtest_url
  alert_email         = var.alert_email
}
