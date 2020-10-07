variable "gcp_project" {
  type = string
}

variable "azure_hostname" {
  default = "azure-ubuntu-arc"
}

variable "gcp_hostname" {
  default = "gcp-ubuntu-arc"
}

variable "aws_profile" {
  default = "terraform"
}

variable "aws_hostname" {
  default = "aws-ubuntu-arc"
}

variable "ssh_user" {
  type = string
}

// Defaulted variable declarations

variable "ssh_pub_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

variable "gcp_region" {
  default = "europe-west2" // London
}

variable "gcp_credentials" {
  default = "~/.gcp/account.json"
}

variable "resource_group" {
  default = "azure-arc"
}

variable "service_principal_name" {
  # Will default to arc-$subscription_id
  default = ""
}

variable "location" {
  default = "West Europe"
}