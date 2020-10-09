data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

locals {
  arc = {
    tenant_id                = data.azurerm_subscription.current.tenant_id
    subscription_id          = data.azurerm_subscription.current.subscription_id
    service_principal_appid  = azuread_service_principal.arc.application_id
    service_principal_secret = random_password.arc.result
    resource_group_name      = azurerm_resource_group.arc.name
    location                 = azurerm_resource_group.arc.location
  }
}

resource "azuread_application" "arc" {
  name = "arc-${data.azurerm_subscription.current.subscription_id}"
}

resource "azuread_service_principal" "arc" {
  application_id = azuread_application.arc.application_id
}

resource "random_pet" "arc" {}

resource "random_password" "arc" {
  length           = 16
  special          = true
  override_special = "!@#%()-_"

  keepers = {
    service_principal = azuread_service_principal.arc.id
  }
}

resource "azuread_service_principal_password" "arc" {
  service_principal_id = azuread_service_principal.arc.id
  value                = random_password.arc.result
  end_date             = timeadd(timestamp(), "8760h")
  # Valid for a year
  # Lifecycle stops end_date being recalculated on each run
  # Taint the resource to change the date
  lifecycle {
    ignore_changes = [end_date]
  }

  # Give it chance to succeed
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

resource "azurerm_resource_group" "arc" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_resource_group" "arc-monitor" {
  name     = "${var.resource_group_name}-monitor"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "arc" {
  name                = "arc-monitor-logs-workspace-${random_pet.arc.id}"
  location            = azurerm_resource_group.arc-monitor.location
  resource_group_name = azurerm_resource_group.arc-monitor.name
  sku                 = "Free"
}

resource "azurerm_role_assignment" "arc" {
  role_definition_name = "Azure Connected Machine Onboarding"
  principal_id         = azuread_service_principal.arc.id
  scope                = azurerm_resource_group.arc.id
}

module "policy" {
  source           = "./module/policy"
  assignment_scope = azurerm_resource_group.arc.id
}

module "aws" {
  source     = "./module/aws"
  depends_on = [azuread_service_principal_password.arc, ]
  for_each   = toset(var.aws_hostnames)
  hostname   = each.value
  arc        = local.arc
}

module "gcp" {
  source     = "./module/gcp"
  depends_on = [azuread_service_principal_password.arc, ]
  for_each   = toset(var.gcp_hostnames)
  hostname   = each.value
  arc        = local.arc
}
