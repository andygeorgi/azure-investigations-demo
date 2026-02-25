variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "westeurope"
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
