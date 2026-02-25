variable "amw_name" {
  type        = string
  description = "Name of the Azure Monitor Workspace."
}

variable "location" {
  type        = string
  description = "Azure region for the AMW."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to create the AMW."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID used for the subscription-level AMW association."
}

variable "principal_id" {
  type        = string
  description = "Object ID of the principal to which the RBAC role will be assigned (if assign_role = true)."
}

variable "assign_role" {
  type        = bool
  description = "Whether to assign an RBAC role on the AMW to the principal."
  default     = true
}

variable "role_definition_name" {
  type        = string
  description = "Role to assign on the AMW. Valid values: Contributor, Monitoring Contributor, Issue Contributor."
  default     = "Monitoring Contributor"
}
