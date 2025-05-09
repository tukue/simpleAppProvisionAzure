data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "key_vault" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

# SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-${var.environment}-${var.unique_suffix}"
  resource_group_name          = var.resource_group_name
  location                     = var.region
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = random_password.sql_password.result
  minimum_tls_version          = "1.2"
  tags                         = var.common_tags
  
  public_network_access_enabled = false
  
  # Azure AD administrator block is optional
  # azuread_administrator {
  #   login_username = var.azure_ad_admin_username
  #   object_id      = var.azure_ad_admin_object_id
  # }
}

# SQL Database
resource "azurerm_mssql_database" "database" {
  name                = "sqldb-${var.environment}"
  server_id           = azurerm_mssql_server.sql_server.id
  sku_name            = "Basic"
  max_size_gb         = 2
  read_scale          = false
  zone_redundant      = false
  tags                = var.common_tags
  
  # Uncomment if you need short-term backup retention policy
  # short_term_retention_policy {
  #   retention_days = 7
  # }
}

# Virtual Network Rule for SQL Server
resource "azurerm_mssql_virtual_network_rule" "sql_vnet_rule" {
  name                = "sql-vnet-rule"
  server_id           = azurerm_mssql_server.sql_server.id
  subnet_id           = var.subnet_id
}

# Generate random password for SQL admin
resource "random_password" "sql_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_password.result
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = var.key_vault_id
  tenant_id    = var.azure_tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete"]
}

resource "azurerm_mssql_firewall_rule" "allow_specific_ips" {
  name             = "AllowSpecificIPs"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "20.42.136.100" # Replace with your specific IP range
  end_ip_address   = "20.42.136.200" # Replace with your specific IP range
}

resource "azurerm_storage_account" "backup" {
  name                     = "st${var.unique_suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.common_tags
}

resource "azurerm_mssql_server_extended_auditing_policy" "auditing_policy" {
  server_id                  = azurerm_mssql_server.sql_server.id
  storage_endpoint           = var.storage_endpoint
  storage_account_access_key = var.storage_access_key
  retention_in_days          = 90 # Adjust as needed
}





