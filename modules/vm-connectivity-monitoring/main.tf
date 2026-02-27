locals {
  connectivity_block_rule_name = "deny-outbound-https"
  target_network_watcher_name  = "NetworkWatcher_${var.location}"
}

resource "random_password" "vm_admin" {
  length      = 20
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
  special     = true
}

resource "azurerm_virtual_network" "vm_vnet" {
  name                = var.vm_vnet_name
  address_space       = ["10.40.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = var.vm_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = ["10.40.1.0/24"]
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = var.vm_nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "vm_subnet_nsg" {
  subnet_id                 = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_network_security_rule" "deny_https_outbound" {
  count = var.vm_connectivity_block_outbound_443 ? 1 : 0

  name                        = local.connectivity_block_rule_name
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.vm_nsg.name
}

resource "azurerm_network_interface" "vm_nic" {
  name                = var.vm_nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  admin_password      = random_password.vm_admin.result

  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.vm_nic.id]

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  depends_on = [azurerm_subnet_network_security_group_association.vm_subnet_nsg]
}

resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

resource "azurerm_virtual_machine_extension" "network_watcher_agent" {
  name                       = "NetworkWatcherAgentLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.NetworkWatcher"
  type                       = "NetworkWatcherAgentLinux"
  type_handler_version       = "1.4"
  auto_upgrade_minor_version = true
}

resource "azurerm_monitor_data_collection_rule" "vm_dcr" {
  name                = var.vm_dcr_name
  location            = var.location
  resource_group_name = var.resource_group_name

  destinations {
    log_analytics {
      workspace_resource_id = var.law_id
      name                  = "law-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Heartbeat"]
    destinations = ["law-destination"]
  }

  depends_on = [azurerm_virtual_machine_extension.ama]
}

resource "azurerm_monitor_data_collection_rule_association" "vm_dcr_assoc" {
  name                    = "${var.vm_name}-connectivity-dcr-association"
  target_resource_id      = azurerm_linux_virtual_machine.vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_dcr.id
}

data "azurerm_resources" "network_watchers" {
  type = "Microsoft.Network/networkWatchers"
}

locals {
  existing_network_watcher_ids = [
    for nw in data.azurerm_resources.network_watchers.resources : nw.id
    if lower(nw.name) == lower(local.target_network_watcher_name)
  ]

  existing_network_watcher_id = try(local.existing_network_watcher_ids[0], null)
}

resource "azurerm_network_watcher" "vm_nw" {
  count = local.existing_network_watcher_id == null ? 1 : 0

  name                = local.target_network_watcher_name
  location            = var.location
  resource_group_name = "NetworkWatcherRG"
}

resource "azurerm_network_connection_monitor" "vm_to_azure_monitor" {
  name               = "${var.vm_name}-cm"
  network_watcher_id = local.existing_network_watcher_id != null ? local.existing_network_watcher_id : azurerm_network_watcher.vm_nw[0].id
  location           = var.location

  endpoint {
    name               = "source-vm"
    target_resource_id = azurerm_linux_virtual_machine.vm.id
  }

  endpoint {
    name    = "azure-monitor-endpoint"
    address = "global.handler.control.monitor.azure.com"
  }

  test_configuration {
    name              = "tcp-443"
    protocol          = "Tcp"
    test_frequency_in_seconds = 60

    tcp_configuration {
      port = 443
    }

    success_threshold {
      checks_failed_percent = 10
      round_trip_time_ms    = 100
    }
  }

  test_group {
    name                     = "vm-to-azure-monitor"
    destination_endpoints    = ["azure-monitor-endpoint"]
    source_endpoints         = ["source-vm"]
    test_configuration_names = ["tcp-443"]
  }

  depends_on = [azurerm_virtual_machine_extension.network_watcher_agent]
}

resource "azurerm_monitor_action_group" "vm_ag" {
  name                = var.vm_action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "vmconagt"

  email_receiver {
    name                    = "ScenarioEmail"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "connectivity_alert" {
  name                = var.vm_alert_name
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_network_connection_monitor.vm_to_azure_monitor.id]
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  description         = "Fires when VM cannot reach Azure Monitor endpoint over TCP 443 due to network settings."

  criteria {
    metric_namespace = "Microsoft.Network/networkWatchers/connectionMonitors"
    metric_name      = "ChecksFailedPercent"
    aggregation      = "Average"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.vm_ag.id
  }
}
