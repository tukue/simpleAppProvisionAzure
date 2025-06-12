// Commented out undeclared resources to avoid errors during Terraform plan/apply

// output "public_ip_address" {
//   value = azurerm_public_ip.bastion_pip.ip_address
// }

// output "vmss_name" {
//   value = azurerm_linux_virtual_machine_scale_set.vmss.name
// }

// output "sql_server_name" {
//   value = azurerm_mssql_server.sql_server.name
// }

// output "database_name" {
//   value = azurerm_mssql_database.database.name
// }

// output "sql_server_fqdn" {
//   value = azurerm_mssql_server.sql_server.fully_qualified_domain_name
// }

// output "sql_connection_string" {
//   value     = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.database.name};Persist Security Info=False;User ID=${var.sql_admin_login};Password=${random_password.sql_admin_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
//   sensitive = true
// }

// output "sql_credentials" {
//   value = {
//     username = var.sql_admin_login
//     password = random_password.sql_admin_password.result
//     server   = azurerm_mssql_server.sql_server.fully_qualified_domain_name
//     database = azurerm_mssql_database.database.name
//   }
//   sensitive = true
// }

# Resource Group Outputs
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

# Networking Outputs
output "vnet_id" {
  value = module.networking.vnet_id
}

output "app_subnet_id" {
  value = module.networking.app_subnet_id
}

# SQL Server Outputs
output "sql_server_id" {
  description = "ID of the SQL Server"
  value       = module.database.sql_server_id
}

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = module.database.sql_server_name
}

# Monitoring Outputs
output "workspace_id" {
  value = module.monitoring.workspace_id
}



