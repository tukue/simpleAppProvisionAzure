output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "app_subnet_id" {
  value = azurerm_subnet.app_subnet.id
}