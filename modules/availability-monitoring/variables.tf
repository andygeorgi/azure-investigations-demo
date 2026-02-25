variable "law_name" {
  type        = string
  description = "Name of the Log Analytics Workspace."
}

variable "appi_name" {
  type        = string
  description = "Name of the Application Insights component."
}

variable "webtest_name" {
  type        = string
  description = "Name of the classic ping web test."
}

variable "action_group_name" {
  type        = string
  description = "Name of the Monitor Action Group."
}

variable "alert_name" {
  type        = string
  description = "Name of the availability metric alert."
}

variable "location" {
  type        = string
  description = "Azure region for all resources in this module."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to create resources."
}

variable "webtest_url" {
  type        = string
  description = "Public URL probed by the classic ping web test. Set to an invalid URL to intentionally trigger the alert."
}

variable "alert_email" {
  type        = string
  description = "Email address that receives availability alert notifications."
}
