variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "my-resource-group"
}

variable "region" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "swedencentral"

}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "azure_client_id" {
  description = "Azure client ID"
  type        = string
}

variable "azure_client_secret" {
  description = "Azure client secret"
  type        = string
  sensitive   = true
}

variable "vm_name" {
  description = "Name of the VM"
  default     = "my-vm"
}

variable "sql_admin_login" {
  description = "SQL Server admin username"
  default     = "sqladmin"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  default     = "dev"
} 


