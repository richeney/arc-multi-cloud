variable "hostname" {}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_pub_key_file" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "arc" {
  description = "Object containing the Azure Arc azcmagent values."
  type = object({
    tenant_id                = string
    subscription_id          = string
    service_principal_appid  = string
    service_principal_secret = string
    resource_group_name      = string
    location                 = string
  })
}
