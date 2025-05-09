output "sql_server_id" {
  description = "ID of the SQL Server"
  value       = azurerm_mssql_server.sql_server.id
}

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = azurerm_mssql_server.sql_server.name
}

output "sql_server_fqdn" {
  description = "FQDN of the SQL Server"
  value       = azurerm_mssql_server.sql_server.fully_qualified_domain_name
  sensitive   = true
}

output "database_name" {
  description = "Name of the SQL Database"
  value       = azurerm_mssql_database.database.name
}

output "sql_admin_username" {
  description = "SQL Server admin username"
  value       = var.sql_admin_login
  sensitive   = true
}

output "sql_admin_password_secret_id" {
  description = "ID of the SQL admin password secret"
  value       = azurerm_key_vault_secret.sql_admin_password.id
  sensitive   = true
}

output "sql_admin_password" {
  description = "SQL Server admin password"
  value       = random_password.sql_password.result
  sensitive   = true
}
 
 