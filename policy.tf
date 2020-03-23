locals {
  auditPasswordlessRemoteConnections = "/providers/Microsoft.Authorization/policyDefinitions/2d67222d-05fd-4526-a171-2ee132ad9e83"
  auditRequiredPackages              = "/providers/Microsoft.Authorization/policyDefinitions/fee5cb2b-9d9b-410e-afe3-2902d90d0004"
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

resource "azurerm_policy_set_definition" "linux" {
  name         = "LinuxAzureArc"
  policy_type  = "Custom"
  display_name = "Linux policies for Azure Arc"
  description  = "Linux Guest Configuration policies for Hybrid Compute"

  // Requires
  // management_group_id = data.azurerm_client_config.current.tenant_id

  lifecycle {
    ignore_changes = [
      metadata
    ]
  }

  /*
    parameters = <<PARAMETERS
    {
        "packages": {
            "type": "Array",
            "metadata": {
                "displayName": "List of required packages",
                "description": "List of software packages required on Linux."
            },
            "defaultValue": []
        }
    }
PARAMETERS
*/

  policy_definitions = <<POLICY_DEFINITIONS
    [
        {
            "comment": "Audit servers that allow remote connections with no password.",
            "policyDefinitionId": "${local.auditPasswordlessRemoteConnections}"
        }
    ]
POLICY_DEFINITIONS

}

resource "azurerm_policy_assignment" "linux" {
  name                 = "LinuxAzureArc"
  scope                = azurerm_resource_group.arc.id
  policy_definition_id = azurerm_policy_set_definition.linux.id
  description          = "Linux Policies for Azure Arc"
  display_name         = "Audit policy initiative assignment for Linux Azure Arc VMs."
}