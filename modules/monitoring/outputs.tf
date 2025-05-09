output "workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.workspace.id
}

output "workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.workspace.name
}

output "key_vault_id" {
  description = "ID of the Azure Key Vault"
  value       = azurerm_key_vault.key_vault.id
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.key_vault.name
}

