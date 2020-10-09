provider "azurerm" {
  version = "~> 2.30.0"
  features {}
}

provider "azuread" {
  version = "~> 1.0.0"
}

provider "aws" {
  version                 = "~> 2.70.0"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "terraform"
  region                  = "eu-west-2"
}

provider "google" {
  version     = "~> 3.42.0"
  credentials = file("~/.gcp/account.json")
  project     = jsondecode(file("~/.gcp/account.json")).project_id
  region      = "europe-west2"
  zone        = "europe-west2-a"
}

provider "random" {
  version = "~> 2.3.0"
}

provider "local" {
  version = "~> 1.4.0"
}

provider "template" {
  version = "~> 2.1"
}
