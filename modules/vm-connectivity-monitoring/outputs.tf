output "law_id" {
  description = "Resource ID of the shared Log Analytics Workspace used for VM connectivity monitoring."
  value       = var.law_id
}

output "vm_id" {
  description = "Resource ID of the demo Linux VM."
  value       = azurerm_linux_virtual_machine.vm.id
}

output "connectivity_alert_id" {
  description = "Resource ID of the VM connectivity metric alert."
  value       = azurerm_monitor_metric_alert.connectivity_alert.id
}

output "action_group_id" {
  description = "Resource ID of the VM connectivity action group."
  value       = azurerm_monitor_action_group.vm_ag.id
}
