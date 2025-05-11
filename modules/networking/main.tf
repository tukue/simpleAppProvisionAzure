# Networking Module

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
  tags                = var.common_tags
}

# App Subnet
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}

# Database Subnet
resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}

# Bastion Subnet
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.common_tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_public_key_path)
  }

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = var.common_tags
}
