locals {
  auditBadPasswdFilePermissions = "/providers/Microsoft.Authorization/policyDefinitions/e6955644-301c-44b5-a4c4-528577de6861"
  auditRequiredPackages         = "/providers/Microsoft.Authorization/policyDefinitions/d3b823c9-e0fc-4453-9fb2-8213b7338523"
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

resource "azurerm_policy_set_definition" "linux" {
  name         = "LinuxAzureArc"
  policy_type  = "Custom"
  display_name = "Linux policies for Azure Arc"
  description  = "Linux Guest Configuration policies for Hybrid Compute"

  metadata = <<METADATA
    {
      "category": "Azure Arc"
    }
METADATA

  parameters = <<PARAMETERS
    {
        "Packages": {
            "type": "String",
            "defaultValue": "",
            "metadata": {
                "displayName": "List of required packages",
                "description": "Semicolon separate list of software packages required on Linux."
            }
        }
    }
PARAMETERS

  policy_definition_reference {
    policy_definition_id = local.auditBadPasswdFilePermissions
    parameter_values     = <<VALUE
    {
      "IncludeArcMachines": {"value": "true"}
    }
VALUE
  }

  policy_definition_reference {
    policy_definition_id = local.auditRequiredPackages
    parameter_values     = <<VALUE
    {
      "IncludeArcMachines": {"value": "true"},
      "ApplicationName": {"value": "[parameters('Packages')]"}
    }
VALUE
  }
}

resource "azurerm_policy_assignment" "linux" {
  name                 = "LinuxAzureArc"
  scope                = azurerm_resource_group.arc.id
  policy_definition_id = azurerm_policy_set_definition.linux.id
  description          = "Linux Policies for Azure Arc"
  display_name         = "Audit policy initiative assignment for Linux Azure Arc VMs."

  lifecycle {
    ignore_changes = [
      parameters
    ]
  }

  metadata = <<METADATA
    {
      "category": "Azure Arc"
    }
    METADATA

  parameters = <<PARAMETERS
    {
      "Packages": { "value": "jq; aptitude" }
    }
    PARAMETERS
}
