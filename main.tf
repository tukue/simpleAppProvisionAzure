# Configure Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = true
      skip_shutdown_and_force_delete = false
    }
    key_vault {
      purge_soft_delete_on_destroy               = false
      recover_soft_deleted_key_vaults            = true
      recover_soft_deleted_certificates          = true
      recover_soft_deleted_keys                  = true
      recover_soft_deleted_secrets               = true
    }
  }
  subscription_id            = var.azure_subscription_id
  tenant_id                 = var.azure_tenant_id
  client_id                 = var.azure_client_id
  client_secret             = var.azure_client_secret
  skip_provider_registration = false

  # Add timeouts and retry logic
  partner_id                = "terraform"
  disable_correlation_request_id = false
  environment               = "public"
  metadata_host            = "management.azure.com"
  auxiliary_tenant_ids     = []
}

# Add availability zones support
locals {
  availability_zones = ["1", "2", "3"]
  
  common_tags = {
    Environment     = var.environment
    Region         = local.region_config.display_name
    ManagedBy      = "Terraform"
    LastModified   = timestamp()
    CostCenter     = var.cost_center
    BusinessUnit   = var.business_unit
  }
}

# Create Resource Group with improved tags
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${var.region}"
  location = local.region_config.name
  tags     = merge(local.common_tags, {
    Purpose = "Infrastructure"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Create Virtual Network with improved design
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}-${var.region}"
  address_space       = ["10.0.0.0/16"]
  location           = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags               = local.common_tags

  dns_servers = ["168.63.129.16"] # Azure DNS

  subnet {
    name           = "subnet-app"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "subnet-db"
    address_prefix = "10.0.2.0/24"
  }

  subnet {
    name           = "subnet-mgmt"
    address_prefix = "10.0.3.0/24"
  }
}

# Create Azure Bastion Host for secure VM access
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-bastion-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                = "Standard"
  zones              = local.availability_zones
  tags               = local.common_tags
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags               = local.common_tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

# Create VM Scale Set for better availability
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                = "Standard_DS2_v2"
  instances          = 2
  zones              = local.availability_zones
  tags               = local.common_tags

  admin_username = "adminuser"
  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.ssh_public_key_path)
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching             = "ReadWrite"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.app_subnet.id
    }
  }

  health_probe_id = azurerm_lb_probe.vmss_probe.id

  automatic_os_upgrade_policy {
    enable_automatic_os_upgrade = true
    disable_automatic_rollback  = false
  }

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent         = 20
    max_unhealthy_upgraded_instance_percent = 20
    pause_time_between_batches             = "PT1H"
  }
}

# Create Azure SQL Server with high availability
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-${var.environment}-${random_string.unique.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = random_password.sql_admin_password.result
  minimum_tls_version         = "1.2"
  tags                        = local.common_tags

  azuread_administrator {
    login_username = var.azure_ad_admin_username
    object_id     = var.azure_ad_admin_object_id
  }

  identity {
    type = "SystemAssigned"
  }
}

# Create SQL Database with geo-replication
resource "azurerm_mssql_database" "database" {
  name           = "db-${var.environment}"
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 32
  sku_name       = "BC_Gen5_2"
  zone_redundant = true

  short_term_retention_policy {
    retention_days = 7
  }

  long_term_retention_policy {
    weekly_retention  = "P1W"
    monthly_retention = "P1M"
    yearly_retention  = "P1Y"
    week_of_year     = 1
  }

  geo_backup_enabled = true
  tags              = local.common_tags
}

# Add monitoring and diagnostics
resource "azurerm_monitor_diagnostic_setting" "sql_diagnostics" {
  name                       = "sql-diagnostics"
  target_resource_id        = azurerm_mssql_server.sql_server.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  log {
    category = "SQLSecurityAuditEvents"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

# Generate random password
resource "random_password" "sql_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# Allow Azure services to access the SQL Server
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Allow VM to access SQL Server
resource "azurerm_mssql_firewall_rule" "allow_vm" {
  name             = "AllowVM"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = azurerm_public_ip.pip.ip_address
  end_ip_address   = azurerm_public_ip.pip.ip_address
}

# Generate random string for unique naming
resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

# Create Virtual Network Rule for SQL Server
resource "azurerm_mssql_virtual_network_rule" "sql_vnet_rule" {
  name                = "sql-vnet-rule"
  server_id           = azurerm_mssql_server.sql_server.id
  subnet_id           = azurerm_subnet.subnet.id
}

# Allow VM subnet in SQL Server firewall
resource "azurerm_mssql_firewall_rule" "allow_subnet" {
  name             = "AllowSubnet"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = cidrhost(azurerm_subnet.subnet.address_prefixes[0], 0)
  end_ip_address   = cidrhost(azurerm_subnet.subnet.address_prefixes[0], -1)
}








