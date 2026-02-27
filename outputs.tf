output "amw_id" {
  value = module.amw.amw_id
}

output "selected_scenarios" {
  value = var.enabled_scenarios
}

output "amw_subscription_association_id" {
  value = module.amw.subscription_association_id
}

output "application_insights_id" {
  value = try(module.availability[0].application_insights_id, null)
}

output "webtest_id" {
  value = try(module.availability[0].webtest_id, null)
}

output "availability_alert_id" {
  value = try(module.availability[0].availability_alert_id, null)
}

output "vm_id" {
  value = try(module.vm_connectivity[0].vm_id, null)
}

output "vm_law_id" {
  value = azurerm_log_analytics_workspace.shared_law.id
}

output "shared_law_id" {
  value = azurerm_log_analytics_workspace.shared_law.id
}

output "vm_connectivity_alert_id" {
  value = try(module.vm_connectivity[0].connectivity_alert_id, null)
}

output "vm_action_group_id" {
  value = try(module.vm_connectivity[0].action_group_id, null)
}
