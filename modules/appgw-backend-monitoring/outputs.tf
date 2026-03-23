output "appgw_id" {
  description = "Resource ID of the Application Gateway."
  value       = azurerm_application_gateway.appgw.id
}

output "appgw_backend_vm_id" {
  description = "Resource ID of the backend VM."
  value       = azurerm_linux_virtual_machine.backend_vm.id
}

output "appgw_health_alert_id" {
  description = "Resource ID of the backend health metric alert."
  value       = azurerm_monitor_metric_alert.appgw_health_alert.id
}

output "appgw_action_group_id" {
  description = "Resource ID of the App Gateway scenario action group."
  value       = azurerm_monitor_action_group.appgw_ag.id
}
