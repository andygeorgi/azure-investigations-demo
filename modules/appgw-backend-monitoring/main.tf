locals {
  appgw_deny_rule_name = "deny-inbound-http-from-appgw"
}

# -------------------------------------------------------
# Networking
# -------------------------------------------------------

resource "azurerm_virtual_network" "appgw_vnet" {
  name                = var.appgw_vnet_name
  address_space       = ["10.50.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = var.appgw_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.appgw_vnet.name
  address_prefixes     = ["10.50.0.0/24"]

  delegation {
    name = "appgw-delegation"
    service_delegation {
      name = "Microsoft.Network/applicationGateways"
    }
  }
}

resource "azurerm_subnet" "backend_subnet" {
  name                 = var.appgw_backend_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.appgw_vnet.name
  address_prefixes     = ["10.50.1.0/24"]
}

resource "azurerm_network_security_group" "backend_nsg" {
  name                = var.appgw_nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "backend_nsg_assoc" {
  subnet_id                 = azurerm_subnet.backend_subnet.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

# Toggleable deny rule — blocks App Gateway health-probe traffic to the
# backend VM on TCP/80, causing the backend to be marked unhealthy.
resource "azurerm_network_security_rule" "deny_http_from_appgw" {
  count = var.appgw_block_backend_health_probe ? 1 : 0

  name                        = local.appgw_deny_rule_name
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "10.50.0.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.backend_nsg.name
}

# -------------------------------------------------------
# Backend VM (simple HTTP server via cloud-init)
# -------------------------------------------------------

resource "random_password" "backend_admin" {
  length      = 20
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
  special     = true
}

resource "azurerm_network_interface" "backend_nic" {
  name                = var.appgw_backend_vm_nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "backend_vm" {
  name                = var.appgw_backend_vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.appgw_vm_size
  admin_username      = var.appgw_vm_admin_username
  admin_password      = random_password.backend_admin.result

  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.backend_nic.id]

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

  # Python 3 HTTP server — no package installation required.
  custom_data = base64encode(<<-CLOUD_INIT
#!/bin/bash
mkdir -p /var/www/html
cat > /var/www/html/index.html <<'HTML'
<html><body><h1>App Gateway Backend — Healthy</h1><p>This page is served by the demo backend VM.</p></body></html>
HTML

cat > /etc/systemd/system/simplehttp.service <<'UNIT'
[Unit]
Description=Simple HTTP Server for App Gateway health probe
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server 80 --directory /var/www/html
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable simplehttp
systemctl start simplehttp
CLOUD_INIT
  )

  depends_on = [azurerm_subnet_network_security_group_association.backend_nsg_assoc]
}

# -------------------------------------------------------
# Application Gateway v2
# -------------------------------------------------------

resource "azurerm_public_ip" "appgw_pip" {
  name                = var.appgw_pip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.appgw_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  backend_address_pool {
    name         = "backend-pool"
    ip_addresses = [azurerm_network_interface.backend_nic.private_ip_address]
  }

  probe {
    name                = "backend-health-probe"
    protocol            = "Http"
    path                = "/"
    host                = "localhost"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "backend-health-probe"
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "backend-http-settings"
  }

  depends_on = [azurerm_subnet_network_security_group_association.backend_nsg_assoc]
}

# -------------------------------------------------------
# Monitoring — Action Group + Metric Alert
# -------------------------------------------------------

resource "azurerm_monitor_action_group" "appgw_ag" {
  name                = var.appgw_action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "appgwagt"

  email_receiver {
    name                    = "ScenarioEmail"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "appgw_health_alert" {
  name                = var.appgw_alert_name
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_gateway.appgw.id]
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  description         = "Fires when one or more Application Gateway backend hosts are unhealthy."

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.appgw_ag.id
  }
}
