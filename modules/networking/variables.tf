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
}