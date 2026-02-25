# -----------------------------
# Log Analytics Workspace (backing store for workspace-mode App Insights)
# -----------------------------
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.law_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# -----------------------------
# Application Insights (workspace mode)
# -----------------------------
resource "azurerm_application_insights" "appi" {
  name                = var.appi_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
}

# -----------------------------
# Classic ping web test
# -----------------------------
resource "azurerm_application_insights_web_test" "webtest" {
  name                    = var.webtest_name
  location                = azurerm_application_insights.appi.location
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.appi.id

  kind      = "ping"
  frequency = 300
  timeout   = 60
  enabled   = true

  # Classic internal geo-location codes
  geo_locations = [
    "us-tx-sn1-azr",
    "us-il-ch1-azr",
  ]

  configuration = <<XML
<WebTest Name="DemoWebTest" Id="ABD48585-0831-40CB-9069-682EA6BB3583" Enabled="True"
 xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010">
  <Items>
    <Request Method="GET" Version="1.1" Url="${var.webtest_url}" Timeout="300"
      ParseDependentRequests="True" FollowRedirects="True" RecordResult="True"
      Cache="False" ExpectedHttpStatusCode="200" />
  </Items>
</WebTest>
XML
}

# -----------------------------
# Action Group (email notifications)
# -----------------------------
resource "azurerm_monitor_action_group" "ag" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "amwdemo"

  email_receiver {
    name                    = "DemoEmail"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# -----------------------------
# Availability metric alert
# Fires when ≥ 1 geo-location reports the web test as failed.
# -----------------------------
resource "azurerm_monitor_metric_alert" "availability_alert" {
  name                = var.alert_name
  resource_group_name = var.resource_group_name
  description         = "Availability alert for App Insights Web Test (demo)."
  severity            = 2

  # Web test ID must come first for availability alerts
  scopes = [
    azurerm_application_insights_web_test.webtest.id,
    azurerm_application_insights.appi.id,
  ]

  frequency   = "PT1M"
  window_size = "PT5M"

  application_insights_web_test_location_availability_criteria {
    web_test_id           = azurerm_application_insights_web_test.webtest.id
    component_id          = azurerm_application_insights.appi.id
    failed_location_count = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }

  # Portal hidden-link tags for correct alert → resource association
  tags = {
    "hidden-link:${azurerm_application_insights.appi.id}"             = "Resource"
    "hidden-link:${azurerm_application_insights_web_test.webtest.id}" = "Resource"
  }
}
