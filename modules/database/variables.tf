variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "unique_suffix" {
  type = string
}

variable "sql_admin_login" {
  type = string
}

variable "subnet_id" {
  type = string
}