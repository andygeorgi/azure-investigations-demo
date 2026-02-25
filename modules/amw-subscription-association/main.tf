# -----------------------------
# Azure Monitor Workspace
# -----------------------------
resource "azurerm_monitor_workspace" "amw" {
  name                          = var.amw_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = true

  tags = {
    purpose = "issues-investigations-demo"
  }
}

# Optional: RBAC on AMW (Contributor / Monitoring Contributor / Issue Contributor)
resource "azurerm_role_assignment" "amw_role" {
  count                = var.assign_role ? 1 : 0
  scope                = azurerm_monitor_workspace.amw.id
  role_definition_name = var.role_definition_name
  principal_id         = var.principal_id
}

# -----------------------------
# Subscription → AMW association (preview API)
# Wires the AMW as the subscription-level default workspace for
# Issues & Investigations. Uses AzAPI because azurerm does not yet
# support Microsoft.Monitor/settings.
# -----------------------------

# Destroy-time provisioner: removes the ARM association BEFORE Terraform
# deletes the azapi_resource or the AMW itself, preventing orphaned state.
resource "terraform_data" "subscription_amw_cleanup" {
  input = var.subscription_id

  # depends_on ensures this resource is destroyed first (dependents are
  # destroyed before their dependencies).
  depends_on = [azapi_resource.subscription_amw_association]

  provisioner "local-exec" {
    when       = destroy
    command    = "az rest --method DELETE --url https://management.azure.com/subscriptions/${self.input}/providers/Microsoft.Monitor/settings/default?api-version=2025-06-03-preview || echo Subscription AMW association cleanup attempted"
    on_failure = continue
  }
}

resource "azapi_resource" "subscription_amw_association" {
  type      = "Microsoft.Monitor/settings@2025-06-03-preview"
  name      = "default"
  parent_id = "/subscriptions/${var.subscription_id}"

  body = {
    properties = {
      defaultAzureMonitorWorkspace = azurerm_monitor_workspace.amw.id
    }
  }

  schema_validation_enabled = false
  ignore_missing_property   = true
}
