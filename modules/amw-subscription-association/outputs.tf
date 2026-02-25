output "amw_id" {
  description = "Resource ID of the Azure Monitor Workspace."
  value       = azurerm_monitor_workspace.amw.id
}

output "subscription_association_id" {
  description = "Resource ID of the subscription-level AMW association (Microsoft.Monitor/settings/default)."
  value       = azapi_resource.subscription_amw_association.id
}
