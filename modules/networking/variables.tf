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
  type = map(string)
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string

  validation {
    condition     = can(file(var.ssh_public_key_path))
    error_message = "The SSH public key file specified in 'ssh_public_key_path' does not exist or cannot be read. Please provide a valid file path."
  }
}