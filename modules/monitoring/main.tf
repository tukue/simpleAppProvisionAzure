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
  name      = "sql-vnet-rule"
  server_id = azurerm_mssql_server.sql_server.id
  subnet_id = azurerm_subnet.app_subnet.id
}

# Allow VM subnet in SQL Server firewall
resource "azurerm_mssql_firewall_rule" "allow_subnet" {
  name             = "AllowSubnet"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = cidrhost(azurerm_subnet.app_subnet.address_prefixes[0], 0)
  end_ip_address   = cidrhost(azurerm_subnet.app_subnet.address_prefixes[0], -1)
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "law-${var.environment}-${var.unique_suffix}"
  location            = var.region
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.common_tags
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
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.environment}"
  location = var.region
  tags     = local.common_tags
}

resource "azurerm_key_vault" "key_vault" {
  name                = "kv-${var.environment}-${random_string.unique.result}"
  location            = var.region
  resource_group_name = var.resource_group_name
  tenant_id           = var.azure_tenant_id
  sku_name            = "standard"
  tags                = var.common_tags
}

resource "azurerm_key_vault_secret" "client_secret" {
  name         = "azure-client-secret"
  value        = var.azure_client_secret
  key_vault_id = azurerm_key_vault.key_vault.id
}

data "azurerm_key_vault_secret" "client_secret" {
  name         = "azure-client-secret"
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = var.azure_tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete"]
}

data "azurerm_client_config" "current" {}



