variable "aws_hostnames" {
  type        = list(string)
  default     = []
  description = "List of AWS hostnames to create and onboard."
}

variable "gcp_hostnames" {
  type        = list(string)
  default     = []
  description = "List of GCP hostnames to create and onboard."
}

/*
variable "azure_hostname" {
  default = "azure-ubuntu-arc"
}
*/

// Defaulted variable declarations

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_pub_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

variable "resource_group_name" {
  default = "azure-arc"
}

variable "service_principal_name" {
  default = "" # Will default to arc-$subscription_id
}

variable "location" {
  default = "West Europe"
}
