resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "law-${var.environment}-${var.unique_suffix}"
  location            = var.region
  resource_group_name = var.resource_group_name
  sku                = "PerGB2018"
  retention_in_days   = 30
  tags               = var.common_tags
}

resource "azurerm_monitor_diagnostic_setting" "sql_diagnostics" {
  name                       = "sql-diagnostics"
  target_resource_id        = var.sql_server_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  enabled_log {
    category_group = "audit"
  }

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}