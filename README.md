# Azure Infrastructure with Terraform

This project deploys a secure Azure infrastructure consisting of a Linux VM and SQL Database with proper networking and security configurations.

## Architecture

The infrastructure includes:
- Virtual Network with custom subnet
- Linux Virtual Machine
- Azure SQL Server and Database
- Network Security Groups
- Service Endpoints for secure database access

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v0.12 or later)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- SSH key pair for VM access
- Azure subscription with required permissions

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd <project-directory>
   ```

2. **Login to Azure**
   ```bash
   az login
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Configure Variables**
   Create a `terraform.tfvars` file:
   ```hcl
   resource_group_name = "your-rg-name"
   location           = "swedencentral"
   environment        = "dev"
   sql_admin_login    = "sqladmin"
   ```

5. **Deploy Infrastructure**
   ```bash
   terraform plan
   terraform apply
   ```

## Infrastructure Components

### Networking
- Virtual Network 
- Subnet (
- Network Security Group with rules for:
  - SSH (port 22)
  - SQL Server (port 1433)

### Compute
- Linux VM (Ubuntu 18.04 LTS)
- Standard_DS1_v2 size
- SSH key authentication

### Database
- Azure SQL Server
- Basic tier database
- Service Endpoint connectivity
- Firewall rules for VM access

## Security Features

- Network Security Groups for traffic control
- Service Endpoints for secure database access
- SSH key-based authentication for VM
- Automated password generation for SQL Server
- Firewall rules limiting database access

## Accessing Resources

### VM Access
```bash
# SSH into the VM
ssh adminuser@$(terraform output -raw public_ip_address)
```

### Database Access
1. Install SQL Server tools on the VM:
   ```bash
   curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
   curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
   sudo apt-get update
   sudo apt-get install -y mssql-tools unixodbc-dev
   ```

2. Connect to database:
   ```bash
   sqlcmd -S <server-fqdn> -U sqladmin -P <password> -d <database-name>
   ```
   (Get connection details from terraform outputs)

## Available Terraform Outputs

- `public_ip_address`: VM's public IP
- `vm_name`: Name of the virtual machine
- `sql_server_name`: SQL Server name
- `database_name`: Database name
- `sql_server_fqdn`: SQL Server fully qualified domain name
- `sql_connection_string`: Complete database connection string
- `sql_credentials`: Database access credentials

## Maintenance

### Adding Resources
Follow Terraform best practices:
1. Add resource definitions to appropriate `.tf` files
2. Add variables to `variables.tf`
3. Add outputs to `outputs.tf`
4. Update README.md with new components

### Updating Resources
1. Modify the relevant `.tf` files
2. Run `terraform plan` to review changes
3. Apply changes with `terraform apply`


## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Create a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.