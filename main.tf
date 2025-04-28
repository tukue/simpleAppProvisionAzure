terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Configure Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
      recover_soft_deleted_certificates = true
      recover_soft_deleted_keys       = true
      recover_soft_deleted_secrets    = true
    }
  }
  subscription_id = var.azure_subscription_id
  tenant_id      = var.azure_tenant_id
  client_id      = var.azure_client_id
  client_secret  = var.azure_client_secret
}

provider "random" {}

locals {
  common_tags = {
    environment = var.environment
    project     = "simpleAppProvisionAzure"
    owner       = "DevOps Team" 
  }
}

# Generate random string for unique names
resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

# Generate random password for SQL admin
resource "random_password" "sql_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-server-${var.environment}-${random_string.unique.result}"
  location                     = var.region
  resource_group_name          = azurerm_resource_group.rg.name
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = random_password.sql_admin_password.result
  tags                         = local.common_tags
}

# Allow Azure services to access the SQL Server
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Create Virtual Network Rule for SQL Server
resource "azurerm_mssql_virtual_network_rule" "sql_vnet_rule" {
  name                = "sql-vnet-rule"
  server_id           = azurerm_mssql_server.sql_server.id
  subnet_id           = azurerm_subnet.app_subnet.id
}

# Allow VM subnet in SQL Server firewall
resource "azurerm_mssql_firewall_rule" "allow_subnet" {
  name             = "AllowSubnet"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = cidrhost(azurerm_subnet.app_subnet.address_prefixes[0], 0)
  end_ip_address   = cidrhost(azurerm_subnet.app_subnet.address_prefixes[0], -1)
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "law-${var.environment}-${random_string.unique.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                = "PerGB2018"
  retention_in_days   = 30
  tags               = local.common_tags
}

# Remove the allow_vm firewall rule since we're using VMSS
# and update other resources accordingly
# DELETE OR COMMENT OUT:
# resource "azurerm_mssql_firewall_rule" "allow_vm" {
#   name             = "AllowVM"
#   server_id        = azurerm_mssql_server.sql_server.id
#   start_ip_address = azurerm_public_ip.pip.ip_address
#   end_ip_address   = azurerm_public_ip.pip.ip_address
# }

resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip-${var.environment}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Sql"]
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.environment}"
  location = var.region
  tags     = local.common_tags
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "vm-nic-${var.environment}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "app-vm-${var.environment}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]
  size               = "Standard_B2s"
  admin_username     = "azureuser"
  admin_password     = random_password.vm_admin_password.result
  disable_password_authentication = false

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

  tags = local.common_tags
}

resource "random_password" "vm_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "azurerm_mssql_firewall_rule" "allow_vm_subnet" {
  name             = "AllowVMSubnet"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = cidrhost(azurerm_subnet.app_subnet.address_prefixes[0], 0)
  end_ip_address   = cidrhost(azurerm_subnet.app_subnet.address_prefixes[0], -1)
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg-${var.environment}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAppPort"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSHFromPublicIP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22" # SSH port
    source_address_prefix      = var.public_ip_address
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_monitor_diagnostic_setting" "sql_diagnostics" {
  name                       = "sql-diagnostics"
  target_resource_id         = azurerm_mssql_server.sql_server.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "app-vmss-${var.environment}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard_B1s" # Smaller VM size
  instances           = 1              # Reduce the number of instances

  admin_username = "azureuser"
  admin_password = random_password.vm_admin_password.result
  disable_password_authentication = false

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

  network_interface {
    name    = "vmss-nic-${var.environment}"
    primary = true

    ip_configuration {
      name      = "internal"
      subnet_id = azurerm_subnet.app_subnet.id
    }
  }

  tags = local.common_tags
}

resource "azurerm_storage_account" "example" {
  name                     = "storage${random_string.unique.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "cpu-alert-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine_scale_set.vmss.id]
  description         = "Alert for high CPU usage"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.alert_action_group.id
  }
}




resource "azurerm_monitor_action_group" "alert_action_group" {
  name                = "alert-action-group-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "alertgrp"

  email_receiver {
    name          = "email-alert"
    email_address = "your-email@example.com"
    use_common_alert_schema = true
  }

  tags = local.common_tags
}









