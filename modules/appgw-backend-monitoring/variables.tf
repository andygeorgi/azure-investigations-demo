variable "law_id" {
  type        = string
  description = "Resource ID of the shared Log Analytics Workspace used by all scenarios."
}

variable "appgw_name" {
  type        = string
  description = "Name of the Application Gateway."
}

variable "appgw_vnet_name" {
  type        = string
  description = "Name of the VNet hosting the Application Gateway and backend."
}

variable "appgw_subnet_name" {
  type        = string
  description = "Name of the dedicated Application Gateway subnet."
}

variable "appgw_backend_subnet_name" {
  type        = string
  description = "Name of the subnet hosting the backend VM."
}

variable "appgw_nsg_name" {
  type        = string
  description = "Name of the NSG attached to the backend subnet."
}

variable "appgw_pip_name" {
  type        = string
  description = "Name of the public IP for the Application Gateway frontend."
}

variable "appgw_backend_vm_name" {
  type        = string
  description = "Name of the backend Linux VM."
}

variable "appgw_backend_vm_nic_name" {
  type        = string
  description = "Name of the NIC for the backend VM."
}

variable "appgw_action_group_name" {
  type        = string
  description = "Name of the Action Group for backend health alert."
}

variable "appgw_alert_name" {
  type        = string
  description = "Name of the backend health metric alert."
}

variable "appgw_vm_size" {
  type        = string
  description = "VM size for the backend VM."
}

variable "appgw_vm_admin_username" {
  type        = string
  description = "Admin username for the backend VM."
}

variable "appgw_block_backend_health_probe" {
  type        = bool
  description = "When true, applies an NSG rule blocking inbound TCP/80 from the App Gateway subnet to simulate backend health degradation."
}

variable "location" {
  type        = string
  description = "Azure region for module resources."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where resources are created."
}

variable "alert_email" {
  type        = string
  description = "Email address receiving backend health alert notifications."
}
