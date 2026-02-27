output "law_id" {
  description = "Resource ID of the Log Analytics Workspace."
  value       = var.law_id
}

output "application_insights_id" {
  description = "Resource ID of the Application Insights component."
  value       = azurerm_application_insights.appi.id
}

output "webtest_id" {
  description = "Resource ID of the classic availability web test."
  value       = azurerm_application_insights_web_test.webtest.id
}

output "availability_alert_id" {
  description = "Resource ID of the metric availability alert rule."
  value       = azurerm_monitor_metric_alert.availability_alert.id
}
