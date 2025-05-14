# Simple Azure App Provisioning with Environment-Specific Tagging

This project demonstrates how to provision Azure resources with environment-specific tagging using Terraform and Azure Pipelines.

## Environment-Specific Resource Tagging

Resources are tagged differently based on the environment (dev, staging, prod) to enable:
- Cost allocation and tracking
- Resource governance
- Environment identification
- Operational requirements

### Tag Structure

#### Base Tags (All Environments)
- `environment`: The deployment environment (dev, staging, prod)
- `project`: Project name
- `owner`: Team responsible for the resources
- `provisioner`: Tool used for provisioning (Terraform)

#### Environment-Specific Tags

**Development Environment**
- `criticality`: low
- `cost_center`: dev-cc-123
- `tier`: development

**Staging Environment**
- `criticality`: medium
- `cost_center`: staging-cc-456
- `tier`: pre-production

**Production Environment**
- `criticality`: high
- `cost_center`: prod-cc-789
- `tier`: production
- `backup`: daily

## How It Works

1. Environment-specific variables are defined in `environments/<env>/terraform.tfvars`
2. The Azure Pipeline dynamically generates additional tags based on the selected environment
3. Tags are merged in Terraform using the `local.resource_tags` variable
4. All resources inherit these tags through module parameters

## Usage

To deploy resources with environment-specific tags:

```bash
# For development environment
terraform init -backend-config=environments/dev/backend.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars

# For staging environment
terraform init -backend-config=environments/staging/backend.tfvars
terraform apply -var-file=environments/staging/terraform.tfvars

# For production environment
terraform init -backend-config=environments/prod/backend.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

Or use the Azure Pipeline by selecting the desired environment parameter.