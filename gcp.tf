provider "google" {
  credentials = "${file("~/.google/terraform-azure-arc-account.json ")}"
  project     = "azure-arc-260215"
  region      = "europe-west2"
}