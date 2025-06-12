terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"  # Match the root module version
    }
  }
  required_version = ">= 1.0.0"
}