variable "resource_group_name" {
  description = "Name of the resource group"
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

variable "sql_admin_login" {
  description = "SQL Server admin username"
  type        = string
  default     = "sqladmin"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
}

variable "azure_ad_admin_username" {
  description = "Azure AD SQL Server admin username"
  type        = string
}

variable "azure_ad_admin_object_id" {
  description = "Azure AD SQL Server admin object ID"
  type        = string
}

variable "vm_name" {
  description = "Name of the VM or Bastion"
  type        = string
  default     = "my-vm"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "public_ip_address" {
  description = "Public IP address for the Bastion host"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "region" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "swedencentral"
} 

variable "key_vault_id" {
  description = "ID of the Azure Key Vault"
  type        = string
}