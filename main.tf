data "azurerm_client_config" "current" {}

locals {
  scenario_availability_url_failure = contains(var.enabled_scenarios, "availability-url-failure")
  scenario_vm_connectivity_loss     = contains(var.enabled_scenarios, "vm-connectivity-loss")
  scenario_appgw_backend_unhealthy  = contains(var.enabled_scenarios, "appgw-backend-unhealthy")
}

# -----------------------------
# Resource Group
# -----------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# -----------------------------
# Shared Log Analytics Workspace (single environment for all scenarios)
# -----------------------------
resource "azurerm_log_analytics_workspace" "shared_law" {
  name                = var.law_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# -----------------------------
# Clean up auto-generated smart-detection alert rules
# Azure creates a "Failure Anomalies" smart-detector rule automatically
# when Application Insights is provisioned.  Terraform does not manage it,
# so we delete any remaining alert rules in the RG before destroy.
# -----------------------------
resource "null_resource" "cleanup_smart_detection" {
  depends_on = [module.availability, module.appgw_backend]

  triggers = {
    resource_group_name = azurerm_resource_group.rg.name
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "for id in $(az monitor smart-detector alert-rule list --resource-group ${self.triggers.resource_group_name} --query \"[].id\" -o tsv 2>/dev/null); do echo \"Deleting: $id\"; az monitor smart-detector alert-rule delete --ids \"$id\" --yes 2>/dev/null || true; done"
    interpreter = ["bash", "-c"]
  }
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
  count  = local.scenario_availability_url_failure ? 1 : 0
  source = "./modules/availability-monitoring"

  law_id              = azurerm_log_analytics_workspace.shared_law.id
  appi_name           = var.appi_name
  webtest_name        = var.webtest_name
  action_group_name   = var.action_group_name
  alert_name          = var.alert_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  webtest_url         = var.webtest_url
  alert_email         = var.alert_email
}

# -----------------------------
# Module 3: VM Connectivity Loss Scenario
# Provisions a Linux VM with Azure Monitor Agent and connectivity alerting.
# A toggleable NSG rule can intentionally block outbound 443 to simulate
# connectivity loss caused by network settings.
# -----------------------------
module "vm_connectivity" {
  count  = local.scenario_vm_connectivity_loss ? 1 : 0
  source = "./modules/vm-connectivity-monitoring"

  law_id                          = azurerm_log_analytics_workspace.shared_law.id
  vm_name                         = var.vm_name
  vm_vnet_name                    = var.vm_vnet_name
  vm_subnet_name                  = var.vm_subnet_name
  vm_nsg_name                     = var.vm_nsg_name
  vm_nic_name                     = var.vm_nic_name
  vm_action_group_name            = var.vm_action_group_name
  vm_alert_name                   = var.vm_alert_name
  vm_dcr_name                     = var.vm_dcr_name
  vm_size                         = var.vm_size
  vm_admin_username               = var.vm_admin_username
  vm_connectivity_block_outbound_443 = var.vm_connectivity_block_outbound_443
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  alert_email                     = var.alert_email
}

# -----------------------------
# Module 4: App Gateway Backend Unhealthy Scenario
# Provisions an Application Gateway with a backend VM, health probe,
# and an alert on unhealthy backends.  A toggleable NSG rule blocks
# health-probe traffic to simulate backend health degradation.
# -----------------------------
module "appgw_backend" {
  count  = local.scenario_appgw_backend_unhealthy ? 1 : 0
  source = "./modules/appgw-backend-monitoring"

  law_id                           = azurerm_log_analytics_workspace.shared_law.id
  appgw_name                       = var.appgw_name
  appgw_vnet_name                  = var.appgw_vnet_name
  appgw_subnet_name                = var.appgw_subnet_name
  appgw_backend_subnet_name        = var.appgw_backend_subnet_name
  appgw_nsg_name                   = var.appgw_nsg_name
  appgw_pip_name                   = var.appgw_pip_name
  appgw_backend_vm_name            = var.appgw_backend_vm_name
  appgw_backend_vm_nic_name        = var.appgw_backend_vm_nic_name
  appgw_action_group_name          = var.appgw_action_group_name
  appgw_alert_name                 = var.appgw_alert_name
  appgw_vm_size                    = var.appgw_vm_size
  appgw_vm_admin_username          = var.appgw_vm_admin_username
  appgw_block_backend_health_probe = var.appgw_block_backend_health_probe
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  alert_email                      = var.alert_email
}
