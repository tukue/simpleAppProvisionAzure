variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "region" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
}

variable "unique_suffix" {
  description = "Unique suffix to add to resource names"
  type        = string
}

variable "sql_server_id" {
  description = "ID of the SQL Server for diagnostics"
  type        = string
}

variable "sql_admin_login" {
  description = "SQL Server admin username"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "azure_client_id" {
  description = "Azure Client ID"
  type        = string
}

variable "azure_client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}