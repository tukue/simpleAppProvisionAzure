# Database Module

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





