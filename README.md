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

+---------------------------------------------+
|                 Azure Region                |
|                                             |
|  +---------------------------------------+  |
|  |         Resource Group (rg-dev)       |  |
|  |                                       |  |
|  |  +-------------------------------+    |  |
|  |  |  Virtual Network (vnet-dev)   |    |  |
|  |  |  Address Space: 10.0.0.0/16   |    |  |
|  |  |                               |    |  |
|  |  |  +-------------------------+  |    |  |
|  |  |  |  Subnet (app-subnet)    |  |    |  |
|  |  |  | Address Prefix:         |  |    |  |
|  |  |  | 10.0.1.0/24             |  |    |  |
|  |  |  |                         |  |    |  |
|  |  |  | +---------------------+ |  |    |  |
|  |  |  | | Azure SQL Server    | |  |    |  |
|  |  |  | | (sql-server)        | |  |    |  |
|  |  |  | +---------------------+ |  |    |  |
|  |  |  |                         |  |    |  |
|  |  |  +-------------------------+  |    |  |
|  |  |                               |    |  |
|  |  |  +-------------------------+  |    |  |
|  |  |  |  Subnet (db-subnet)     |  |    |  |
|  |  |  | Address Prefix:         |  |    |  |
|  |  |  | 10.0.2.0/24             |  |    |  |
|  |  |  |                         |  |    |  |
|  |  |  | +---------------------+ |  |    |  |
|  |  |  | | SQL Database        | |  |    |  |
|  |  |  | | (sqldb-dev)         | |  |    |  |
|  |  |  | +---------------------+ |  |    |  |
|  |  |  +-------------------------+  |    |  |
|  |  |                               |    |  |
|  |  |  +-------------------------+  |    |  |
|  |  |  |  Subnet (bastion)       |  |    |  |
|  |  |  | Address Prefix:         |  |    |  |
|  |  |  | 10.0.3.0/24             |  |    |  |
|  |  |  |                         |  |    |  |
|  |  |  | +---------------------+ |  |    |  |
|  |  |  | | Bastion Host        | |  |    |  |
|  |  |  | | (bastion-dev)       | |  |    |  |
|  |  |  | +---------------------+ |  |    |  |
|  |  |  +-------------------------+  |    |  |
|  |  +-------------------------------+    |  |
|  |                                       |  |
|  |  +-------------------------------+    |  |
|  |  | Log Analytics Workspace       |    |  |
|  |  | (dev)                     |    |  |
|  |  +-------------------------------+    |  |
|  |                                       |  |
|  |  +-------------------------------+    |  |
|  |  | Azure Key Vault               |    |  |
|  |  | (kv-dev)                      |    |  |
|  |  +-------------------------------+    |  |
|  +---------------------------------------+  |
|                                             |
+---------------------------------------------+

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

### 3. Configure workspace per environment using terraform.dev.tfvars, terraform_staging.tfvars and terraform.prod.tfvars  

### Creating Terraform Workspaces for Dev, Staging, and Production

Terraform workspaces allow you to manage multiple environments (e.g., dev, staging, production) using the same configuration. Follow these steps to create and use workspaces:

#### 1. Initialize Terraform
Before creating workspaces, initialize Terraform in your project directory:
```bash
terraform init
```

#### 2. Create and Switch Workspaces
Create and switch to the desired workspace (e.g., dev, staging, production):
```bash
# Create a workspace for development
terraform workspace new dev

# Create a workspace for staging
terraform workspace new staging

# Create a workspace for production
terraform workspace new production

# Switch to a specific workspace
terraform workspace select dev
```

#### 3. Plan for a Specific Workspace
Run the `terraform plan` command to preview changes for the active workspace:
```bash
terraform plan -var-file="terraform.dev.tfvars"

.\terraform.ps1 init -var-file="terraform.dev.tfvars"  # to setup credentails for azure account 

.\terraform.ps1 plan -var-file="terraform.dev.tfvars"  

```
Replace `terraform.dev.tfvars` with the appropriate variable file for staging or production (e.g., `terraform.staging.tfvars` or `terraform.prod.tfvars`).

#### 4. Apply Changes
Apply the changes to the active workspace:
```bash
terraform apply -var-file="terraform.dev.tfvars"
```

#### 5. Verify Active Workspace
To confirm the current workspace, use:
```bash
terraform workspace show
```

Repeat these steps for each environment as needed.

### Terraform Deployment Automation Using Azure Pipeline

Automate the deployment of your Terraform configurations using Azure Pipelines. This approach ensures consistent, repeatable, and secure infrastructure provisioning across environments.

#### Key Features:
- CI/CD integration for Terraform workflows.
- Automated validation, plan, and apply stages.
- Secure handling of secrets using Azure Key Vault.
- Environment-specific configurations with variable files.
- Support for multiple Terraform workspaces (e.g., dev, staging, production).

#### Example Pipeline Steps:
1. **Initialize Terraform**  
  Set up the Terraform backend and initialize the working directory.
  ```yaml
  - task: Bash@3
    inputs:
     targetType: 'inline'
     script: |
      terraform init -backend-config="key=$(Build.SourceBranchName).tfstate"
  ```

2. **Validate Configuration**  
  Ensure the Terraform configuration is syntactically valid.
  ```yaml
  - task: Bash@3
    inputs:
     targetType: 'inline'
     script: |
      terraform validate
  ```

3. **Plan Changes**  
  Generate an execution plan for the specified environment.
  ```yaml
  - task: Bash@3
    inputs:
     targetType: 'inline'
     script: |
      terraform plan -var-file="terraform.$(Build.SourceBranchName).tfvars"
  ```

4. **Apply Changes**  
  Apply the planned changes to the infrastructure.
  ```yaml
  - task: Bash@3
    inputs:
     targetType: 'inline'
     script: |
      terraform apply -auto-approve -var-file="terraform.$(Build.SourceBranchName).tfvars"
  ```

#### Benefits:
- Streamlined infrastructure management.
- Reduced manual intervention and errors.
- Enhanced security and compliance.
- Faster deployment cycles.

Integrate this pipeline into your Azure DevOps project to simplify and standardize your Terraform deployments.



--------------------
Infarstrcture 
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


