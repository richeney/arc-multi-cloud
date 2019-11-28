variable "gcp-project" {
    type = "string"
}

variable "ssh-user" {
    type = "string"
}

// Defaulted variable declarations

variable "ssh-pub-key-file" {
    default = "~/.ssh/id_rsa.pub"
}

variable "gcp-region" {
    default = "europe-west2" // London
}

variable "gcp-credentials" {
    default = "~/.gcp/account.json"
}
