variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "westeurope"
}

variable "enabled_scenarios" {
  type        = list(string)
  description = "Scenarios to deploy. Supported values: availability-url-failure, vm-connectivity-loss, appgw-backend-unhealthy."
  default     = ["availability-url-failure"]

  validation {
    condition = alltrue([
      for scenario in var.enabled_scenarios : contains([
        "availability-url-failure",
        "vm-connectivity-loss",
        "appgw-backend-unhealthy"
      ], scenario)
    ])
    error_message = "enabled_scenarios contains an unsupported value. Allowed values: availability-url-failure, vm-connectivity-loss, appgw-backend-unhealthy."
  }
}

# -----------------------------
# Resource names
# -----------------------------
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
  default     = "amw-iidemo-rg"
}

variable "amw_name" {
  type        = string
  description = "Name of the Azure Monitor Workspace."
  default     = "amw-iidemo-amw"
}

variable "law_name" {
  type        = string
  description = "Name of the Log Analytics Workspace."
  default     = "amw-iidemo-law"
}

variable "appi_name" {
  type        = string
  description = "Name of the Application Insights component."
  default     = "amw-iidemo-appi"
}

variable "webtest_name" {
  type        = string
  description = "Name of the classic ping web test."
  default     = "amw-iidemo-webtest"
}

variable "action_group_name" {
  type        = string
  description = "Name of the Monitor Action Group."
  default     = "amw-iidemo-ag"
}

variable "alert_name" {
  type        = string
  description = "Name of the availability metric alert."
  default     = "amw-iidemo-avail-alert"
}

variable "vm_name" {
  type        = string
  description = "Name of the demo Linux VM for connectivity scenario."
  default     = "amw-iidemo-vm"
}

variable "vm_vnet_name" {
  type        = string
  description = "Name of the VNet hosting the demo VM."
  default     = "amw-iidemo-vnet"
}

variable "vm_subnet_name" {
  type        = string
  description = "Name of the subnet hosting the demo VM."
  default     = "default"
}

variable "vm_nsg_name" {
  type        = string
  description = "Name of the NSG attached to the VM subnet."
  default     = "amw-iidemo-vm-nsg"
}

variable "vm_nic_name" {
  type        = string
  description = "Name of the NIC for the demo VM."
  default     = "amw-iidemo-vm-nic"
}

variable "vm_action_group_name" {
  type        = string
  description = "Name of the Action Group for VM connectivity alert."
  default     = "amw-iidemo-vm-ag"
}

variable "vm_alert_name" {
  type        = string
  description = "Name of the VM connectivity metric alert."
  default     = "amw-iidemo-vm-connectivity-alert"
}

variable "vm_dcr_name" {
  type        = string
  description = "Name of the data collection rule routing monitoring data to Log Analytics."
  default     = "amw-iidemo-vm-dcr"
}

variable "vm_size" {
  type        = string
  description = "VM size for the demo Linux VM."
  default     = "Standard_B2s"
}

variable "vm_admin_username" {
  type        = string
  description = "Admin username for the demo Linux VM."
  default     = "azureuser"
}

# -----------------------------
# Behaviour
# -----------------------------
variable "alert_email" {
  type        = string
  description = "Email address to receive alert notifications."
  default     = "replace-me@example.com"
}

variable "webtest_url" {
  type        = string
  description = "Public URL probed by the availability web test. Set to an invalid URL to intentionally trigger the alert."
  default     = "https://www.microsoft.com"
}

variable "vm_connectivity_block_outbound_443" {
  type        = bool
  description = "When true, applies an NSG rule that blocks VM outbound TCP 443 to simulate connectivity loss caused by network settings."
  default     = false
}

# -----------------------------
# App Gateway Backend Unhealthy scenario
# -----------------------------
variable "appgw_name" {
  type        = string
  description = "Name of the Application Gateway."
  default     = "amw-iidemo-appgw"
}

variable "appgw_vnet_name" {
  type        = string
  description = "Name of the VNet hosting the Application Gateway and backend."
  default     = "amw-iidemo-appgw-vnet"
}

variable "appgw_subnet_name" {
  type        = string
  description = "Name of the dedicated Application Gateway subnet."
  default     = "appgw"
}

variable "appgw_backend_subnet_name" {
  type        = string
  description = "Name of the subnet hosting the App Gateway backend VM."
  default     = "backend"
}

variable "appgw_nsg_name" {
  type        = string
  description = "Name of the NSG attached to the App Gateway backend subnet."
  default     = "amw-iidemo-appgw-nsg"
}

variable "appgw_pip_name" {
  type        = string
  description = "Name of the public IP for the Application Gateway."
  default     = "amw-iidemo-appgw-pip"
}

variable "appgw_backend_vm_name" {
  type        = string
  description = "Name of the backend VM for the App Gateway scenario."
  default     = "amw-iidemo-appgw-vm"
}

variable "appgw_backend_vm_nic_name" {
  type        = string
  description = "Name of the NIC for the App Gateway backend VM."
  default     = "amw-iidemo-appgw-vm-nic"
}

variable "appgw_action_group_name" {
  type        = string
  description = "Name of the Action Group for App Gateway backend health alert."
  default     = "amw-iidemo-appgw-ag"
}

variable "appgw_alert_name" {
  type        = string
  description = "Name of the App Gateway backend health metric alert."
  default     = "amw-iidemo-appgw-health-alert"
}

variable "appgw_vm_size" {
  type        = string
  description = "VM size for the App Gateway backend VM."
  default     = "Standard_B2s"
}

variable "appgw_vm_admin_username" {
  type        = string
  description = "Admin username for the App Gateway backend VM."
  default     = "azureuser"
}

variable "appgw_block_backend_health_probe" {
  type        = bool
  description = "When true, applies an NSG rule blocking inbound TCP/80 from the App Gateway subnet to simulate backend health degradation."
  default     = false
}

variable "assign_amw_role" {
  type        = bool
  description = "Assign an RBAC role on the AMW to the current principal."
  default     = true
}

# Valid values: Contributor, Monitoring Contributor, Issue Contributor
variable "amw_role_definition_name" {
  type        = string
  description = "Role to grant on the Azure Monitor Workspace."
  default     = "Monitoring Contributor"
}
