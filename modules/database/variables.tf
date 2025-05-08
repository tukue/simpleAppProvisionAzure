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

variable "sql_admin_login" {
  description = "SQL Server admin username"
  type        = string
  default     = "sqladmin"
}

variable "subnet_id" {
  description = "ID of the subnet to connect to SQL Server"
  type        = string
}

# Optional variables for Azure AD admin
variable "azure_ad_admin_username" {
  description = "Azure AD admin username for SQL Server"
  type        = string
  default     = ""
}

variable "azure_ad_admin_object_id" {
  description = "Azure AD admin object ID for SQL Server"
  type        = string
  default     = ""
}

variable "key_vault_id" {
  description = "ID of the Azure Key Vault"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}


