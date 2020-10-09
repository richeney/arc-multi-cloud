variable "assignment_scope" {
  type        = string
  description = "Full scope resourceId, e.g. management group or subscription."
}

variable "packages" {
  type        = list
  default     = ["jq", "tree"]
  description = "List of Ubuntu apt packages required on the system."
}

variable "management_group_name" {
  type        = string
  default     = null
  description = "Management group name for policy initiative definition. Defaults to subscription."
}
