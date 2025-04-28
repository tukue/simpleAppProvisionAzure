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


variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "cost_center" {
  description = "Cost center for resource tagging"
  type        = string
  default     = "IT-Infrastructure"
}

variable "business_unit" {
  description = "Business unit for resource tagging"
  type        = string
  default     = "Technology"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
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
  description = "Name of the VM"
  default     = "my-vm"
}

variable "sql_admin_login" {
  description = "SQL Server admin username"
  default     = "sqladmin"
}

variable "public_ip_address" {
  description = "Public IP address for the VM or Bastion"
  type        = string
}



