# Azure Infrastructure with Terraform

This project deploys a secure Azure infrastructure consisting of Linux VM Scale Sets, SQL Database, and Key Vault integration with proper networking and security configurations.

## Architecture

The infrastructure includes:
- Virtual Network with custom subnets (app, database, management)
- Linux Virtual Machine Scale Set for high availability
- Azure SQL Server and Database with geo-replication
- Network Security Groups with strict access rules
- Azure Bastion for secure VM access
- Azure Key Vault for secrets management
- Service Endpoints for secure database access

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v0.12 or later)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- SSH key pair for VM access
- Azure subscription with required permissions

## Security Setup

### 1. Create Azure Service Principal

```bash
# Login to Azure
az login

# Create Service Principal
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

### 2. Set up Key Vault

```bash
# Create Resource Group
az group create --name "rg-keyvault" --location "swedencentral"

# Create Key Vault
az keyvault create \
    --name "kv-terraform-secrets" \
    --resource-group "rg-keyvault" \
    --location "swedencentral"

# Store Service Principal Secret
az keyvault secret set \
    --vault-name "kv-terraform-secrets" \
    --name "AZURE-CLIENT-SECRET" \
    --value "YOUR_CLIENT_SECRET"
```

### 3. Configure Environment

Create a `.env` file based on `env.example`:
```bash
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
ENVIRONMENT=dev
REGION=swedencentral
RESOURCE_GROUP_NAME=your-resource-group
```

## Deployment

1. **Clone and Initialize**
   ```bash
   git clone <repository-url>
   cd <project-directory>
   terraform init
   ```

2. **Configure Variables**
   Create a `terraform.tfvars` file:
   ```hcl
   environment        = "dev"
   location          = "swedencentral"
   ```

3. **Deploy Infrastructure**
   ```bash
   ./terraform.sh plan
   ./terraform.sh apply
   ```

## Infrastructure Components

### Compute
- Linux VM Scale Set
  - Ubuntu 18.04 LTS
  - Standard_DS2_v2 size
  - Auto-scaling enabled
  - Zone redundant deployment
  - Rolling updates configuration

### Networking
- Virtual Network with segregated subnets:
  - Application subnet
  - Database subnet
  - Management subnet
- Azure Bastion Host
- Network Security Groups with:
  - SSH access via Bastion
  - SQL Server access
  - Application-specific rules

### Database
- Azure SQL Server
  - Geo-replication enabled
  - Azure AD authentication
  - TLS 1.2 enforced
- SQL Database
  - Business Critical tier
  - Zone redundant
  - Automated backups
  - Long-term retention

### Security
- Azure Key Vault integration
- Service Principal with minimal permissions
- Network Security Groups
- Azure Bastion for secure VM access
- Service Endpoints
- Azure AD integration

## Resource Access

### VM Access
```bash
# Access VM through Azure Bastion
az network bastion ssh \
    --name "bastion-dev" \
    --resource-group "your-rg" \
    --target-resource-id $(terraform output -raw vmss_id) \
    --auth-type ssh-key \
    --username adminuser \
    --ssh-key ~/.ssh/id_rsa
```

### Database Access
```bash
# Get connection string
terraform output sql_connection_string

# Connect using SQL tools
sqlcmd -S $(terraform output -raw sql_server_fqdn) \
       -U $(terraform output -raw sql_admin_username) \
       -P $(terraform output -raw sql_admin_password) \
       -d $(terraform output -raw database_name)
```

## Maintenance

### Secret Rotation
```bash
# Rotate Service Principal secret
az ad sp credential reset \
    --name "terraform-sp" \
    --append \
    --credential-description "terraform-secret-$(date +%Y%m%d)" \
    --query password -o tsv | \
az keyvault secret set \
    --vault-name "kv-terraform-secrets" \
    --name "AZURE-CLIENT-SECRET" \
    --value @-
```

### Infrastructure Updates
1. Update Terraform configurations
2. Run plan to review changes:
   ```bash
   ./terraform.sh plan
   ```
3. Apply changes:
   ```bash
   ./terraform.sh apply
   ```

### Monitoring
- Azure Monitor integration
- Log Analytics workspace
- VM Scale Set metrics
- SQL Server auditing
- Key Vault logging
- Geo-replicated SQL Database
- Zone redundant VM Scale Set
- Automated backups
- Point-in-time recovery
- Resource locks on critical components

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Create a pull request

## Security Notes

- Never commit sensitive data
- Use Key Vault for all secrets
- Rotate credentials regularly
- Monitor access logs
- Keep dependencies updated
- Follow least privilege principle

## License

This project is licensed under the MIT License - see the LICENSE file for details.
