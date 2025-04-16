# Configure Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
}

locals {
  region_config = local.regions[var.region]
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${var.region}"
  location = local.region_config.name

  tags = {
    Environment = var.environment
    Region      = local.region_config.display_name
  }
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location           = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "my-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
  service_endpoints    = ["Microsoft.Sql"]

  # Required for the virtual network rule
  enforce_private_link_endpoint_network_policies = false
}

# Create Public IP
resource "azurerm_public_ip" "pip" {
  name                = "my-public-ip"
  location           = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "my-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Existing SSH rule
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Add SQL Server rule
  security_rule {
    name                       = "SQL"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range     = "1433"
    source_address_prefix      = azurerm_subnet.subnet.address_prefixes[0]
    destination_address_prefix = "Sql"  # Azure SQL service tag
  }

  tags = {
    environment = var.environment
  }
}

# Create Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "my-nic"
  location           = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Connect NSG to NIC
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "my-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  size               = "Standard_DS1_v2"
  admin_username     = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/tukue/.ssh/aws_ec2_terraform.pub")  # Using absolute path
  }

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
}

# Generate random password
resource "random_password" "sql_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# Create Azure SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-${var.environment}-${random_string.unique.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = random_password.sql_admin_password.result

  public_network_access_enabled = true

  tags = {
    environment = var.environment
  }
}

# Create SQL Database
resource "azurerm_mssql_database" "database" {
  name           = "db-${var.environment}"
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "Basic"
  zone_redundant = false

  tags = {
    environment = var.environment
  }
}

# Allow Azure services to access the SQL Server
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Allow VM to access SQL Server
resource "azurerm_mssql_firewall_rule" "allow_vm" {
  name             = "AllowVM"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = azurerm_public_ip.pip.ip_address
  end_ip_address   = azurerm_public_ip.pip.ip_address
}

# Generate random string for unique naming
resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

# Create Virtual Network Rule for SQL Server
resource "azurerm_mssql_virtual_network_rule" "sql_vnet_rule" {
  name                = "sql-vnet-rule"
  server_id           = azurerm_mssql_server.sql_server.id
  subnet_id           = azurerm_subnet.subnet.id
}

# Allow VM subnet in SQL Server firewall
resource "azurerm_mssql_firewall_rule" "allow_subnet" {
  name             = "AllowSubnet"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = cidrhost(azurerm_subnet.subnet.address_prefixes[0], 0)
  end_ip_address   = cidrhost(azurerm_subnet.subnet.address_prefixes[0], -1)
}



