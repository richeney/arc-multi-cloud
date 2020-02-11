provider "azurerm" {
    version = "=1.40.0"
}

provider "azuread" {
  version = "=0.7.0"
}

provider "random" {
    version = "=2.2.1"
}

provider "local" {
    version = "= 1.4"
}

data "azurerm_subscription" "arc" {
    # Get current subscription_id
}

locals {
    // name = var.service_principal_name != "" ? var.service_principal_name : "arc-${data.azurerm_subscription.arc.subscription_id}"
    name = "arc-${data.azurerm_subscription.arc.subscription_id}"
    ssh_private_key_file = trimsuffix(var.ssh_pub_key_file, ".pub")
}

resource "azuread_application" "arc" {
    name = local.name
}

resource "azuread_service_principal" "arc" {
    application_id = azuread_application.arc.application_id

}

resource "random_password" "arc" {
    length  = 16
    special = true
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
        ignore_changes = [ end_date ]
    }

    # Give it chance to succeed
    provisioner "local-exec" {
        command = "sleep 30"
    }
}

resource "azurerm_resource_group" "arc" {
    name        = var.resource_group
    location    = var.location
}

resource "azurerm_role_assignment" "arc" {
    role_definition_name = "Azure Connected Machine Onboarding"
    principal_id         = azuread_service_principal.arc.id
    scope                = azurerm_resource_group.arc.id
}