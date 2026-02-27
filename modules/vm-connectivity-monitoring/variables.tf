variable "law_id" {
  type        = string
  description = "Resource ID of the shared Log Analytics Workspace used by all scenarios."
}

variable "vm_name" {
  type        = string
  description = "Name of the demo Linux VM."
}

variable "vm_vnet_name" {
  type        = string
  description = "Name of the VNet hosting the demo VM."
}

variable "vm_subnet_name" {
  type        = string
  description = "Name of the subnet hosting the demo VM."
}

variable "vm_nsg_name" {
  type        = string
  description = "Name of the NSG attached to the VM subnet."
}

variable "vm_nic_name" {
  type        = string
  description = "Name of the NIC for the demo VM."
}

variable "vm_action_group_name" {
  type        = string
  description = "Name of the Action Group for VM connectivity alert."
}

variable "vm_alert_name" {
  type        = string
  description = "Name of the VM connectivity metric alert."
}

variable "vm_dcr_name" {
  type        = string
  description = "Name of the data collection rule for VM monitoring routing."
}

variable "vm_size" {
  type        = string
  description = "VM size for the demo Linux VM."
}

variable "vm_admin_username" {
  type        = string
  description = "Admin username for the demo Linux VM."
}

variable "vm_connectivity_block_outbound_443" {
  type        = bool
  description = "When true, applies an NSG rule blocking outbound TCP/443 to simulate connectivity loss from network misconfiguration."
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
  description = "Email address receiving connectivity alert notifications."
}
