output "vnet_id" {
  description = "ID of the created virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "app_subnet_id" {
  description = "ID of the application subnet"
  value       = azurerm_subnet.app_subnet.id
}

output "db_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.db_subnet.id
}

output "bastion_subnet_id" {
  description = "ID of the bastion subnet"
  value       = azurerm_subnet.bastion_subnet.id
}
