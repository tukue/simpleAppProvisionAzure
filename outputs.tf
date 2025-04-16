output "public_ip_address" {
  value = azurerm_public_ip.pip.ip_address
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql_server.name
}

output "database_name" {
  value = azurerm_mssql_database.database.name
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}

output "sql_connection_string" {
  value     = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.database.name};Persist Security Info=False;User ID=${var.sql_admin_login};Password=${random_password.sql_admin_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive = true
}

output "sql_credentials" {
  value = {
    username = var.sql_admin_login
    password = random_password.sql_admin_password.result
    server   = azurerm_mssql_server.sql_server.fully_qualified_domain_name
    database = azurerm_mssql_database.database.name
  }
  sensitive = true
}

