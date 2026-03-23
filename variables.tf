variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "westeurope"
}

variable "name_prefix" {
  type        = string
  description = "Prefix used to derive all resource names (e.g. '<prefix>-rg', '<prefix>-appgw'). Change this to deploy multiple instances side by side."
  default     = "amw-iidemo"
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

variable "vm_size" {
  type        = string
  description = "VM size for demo VMs (used by vm-connectivity-loss and appgw-backend-unhealthy scenarios)."
  default     = "Standard_B2s"
}

variable "vm_admin_username" {
  type        = string
  description = "Admin username for demo VMs."
  default     = "azureuser"
}

variable "vm_connectivity_block_outbound_443" {
  type        = bool
  description = "When true, applies an NSG rule that blocks VM outbound TCP 443 to simulate connectivity loss caused by network settings."
  default     = false
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
