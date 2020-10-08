locals {
  tags = {
    cloud      = "azure"
    hostname   = var.azure_hostname
    managed_by = "azure"
  }
}

resource "azurerm_public_ip" "arc" {
  name                = "${var.azure_hostname}-pip"
  location            = azurerm_resource_group.arc.location
  resource_group_name = azurerm_resource_group.arc.name
  tags                = local.tags

  allocation_method = "Static"
  domain_name_label = var.azure_hostname
}

resource "azurerm_virtual_network" "arc" {
  name                = "arc"
  location            = azurerm_resource_group.arc.location
  resource_group_name = azurerm_resource_group.arc.name
  tags                = local.tags

  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "arc" {
  name                 = "arc"
  resource_group_name  = azurerm_resource_group.arc.name
  virtual_network_name = azurerm_virtual_network.arc.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_log_analytics_workspace" "arc" {
  name                = "arc-monitor-logs-workspace"
  location            = azurerm_resource_group.arc.location
  resource_group_name = azurerm_resource_group.arc.name
  tags                = local.tags
  sku                 = "Free"
}

resource "azurerm_network_security_group" "arc" {
  name                = "${var.azure_hostname}-nsg"
  location            = azurerm_resource_group.arc.location
  resource_group_name = azurerm_resource_group.arc.name
  tags                = local.tags

  security_rule {
    name                       = "AllowSSH"
    description                = "Allow SSH in from all locations"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "arc" {
  name                = "${var.azure_hostname}-nic"
  location            = azurerm_resource_group.arc.location
  resource_group_name = azurerm_resource_group.arc.name
  tags                = local.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.arc.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.arc.id
  }
}

resource "azurerm_network_interface_security_group_association" "arc" {
  network_interface_id      = azurerm_network_interface.arc.id
  network_security_group_id = azurerm_network_security_group.arc.id
}

resource "azurerm_virtual_machine" "arc" {
  name                          = var.azure_hostname
  location                      = azurerm_resource_group.arc.location
  resource_group_name           = azurerm_resource_group.arc.name
  tags                          = local.tags
  vm_size                       = "Standard_DS1_v2"
  network_interface_ids         = [azurerm_network_interface.arc.id]
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.azure_hostname}-os"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name  = var.azure_hostname
    admin_username = var.ssh_user
    // TODO: This custom data line isn't working
    custom_data = "sudo apt-get update && sudo apt-get install -yq aptitude tree jq && sudo apt-get dist-upgrade -yq"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.ssh_user}/.ssh/authorized_keys"
      key_data = file(var.ssh_pub_key_file)
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "monitor-agent" {
  name = "${var.azure_hostname}-monitor"
  tags = local.tags

  virtual_machine_id         = azurerm_virtual_machine.arc.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.13"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
        {
          "workspaceId": "${azurerm_log_analytics_workspace.arc.workspace_id}"
        }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
        {
          "workspaceKey": "${azurerm_log_analytics_workspace.arc.secondary_shared_key}"
        }
PROTECTED_SETTINGS
}

output "azure_ssh" {
  value = "ssh ${var.ssh_user}@${azurerm_public_ip.arc.ip_address}"
}

output "azure_public_ip" {
  value = azurerm_public_ip.arc.ip_address
}