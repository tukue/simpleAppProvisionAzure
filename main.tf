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
  tenant_id       = var.azure_tenant_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
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

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name != "" ? var.resource_group_name : "rg-${var.environment}"
  location = var.region
  tags     = local.common_tags
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  environment         = var.environment
  region              = var.region
  resource_group_name = azurerm_resource_group.rg.name
  common_tags         = local.common_tags
} 

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  environment         = var.environment
  region              = var.region
  resource_group_name = azurerm_resource_group.rg.name
  common_tags         = var.common_tags
  unique_suffix       = random_string.unique.result
  sql_server_id       = module.database.sql_server_id

  azure_subscription_id = var.azure_subscription_id
  azure_tenant_id       = var.azure_tenant_id
  azure_client_id       = var.azure_client_id
  azure_client_secret   = var.azure_client_secret
  sql_admin_login       = var.sql_admin_login
}


# Database Module
module "database" {
  source              = "./modules/database"
  environment         = var.environment
  region              = var.region
  resource_group_name = azurerm_resource_group.rg.name
  unique_suffix       = random_string.unique.result
  sql_admin_login     = var.sql_admin_login
  subnet_id           = module.networking.app_subnet_id
  common_tags         = local.common_tags
  key_vault_id        = module.monitoring.key_vault_id
  key_vault_name      = module.monitoring.key_vault_name
  azure_tenant_id     = var.azure_tenant_id
  storage_endpoint    = azurerm_storage_account.backup.primary_blob_endpoint
  storage_access_key  = azurerm_storage_account.backup.primary_access_key
  allowed_ip_address  = var.allowed_ip_address
}

resource "azurerm_mssql_server" "sql_server" {
  depends_on = [module.database] # Implicit dependency on the database module

  name                         = "sql-${var.environment}-${var.unique_suffix}"
  resource_group_name          = var.resource_group_name
  location                     = var.region
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = module.database.sql_admin_password
  minimum_tls_version          = "1.2"
  tags                         = var.common_tags
}

resource "azurerm_mssql_firewall_rule" "allow_specific_ips" {
  name             = "AllowSpecificIP"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = var.start_ip_address
  end_ip_address   = var.end_ip_address
}

# Bastion Host
resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip-${var.environment}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-${var.environment}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.networking.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "law-${var.environment}-${random_string.unique.result}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

data "azurerm_key_vault" "key_vault" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}


resource "azurerm_storage_account" "backup" {
  name                     = "st${random_string.unique.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "app_subnet_id" {
  value = module.networking.app_subnet_id
}

output "sql_server_id" {
  value = module.database.sql_server_id
}

output "sql_server_name" {
  value = module.database.sql_server_name
}

output "workspace_id" {
  value = module.monitoring.workspace_id
}





