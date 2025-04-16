#!/bin/bash

# Generate random string for defaults
generate_random() {
    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c $1
}

# Set default values for required variables
set_default_values() {
    # Try to get subscription and tenant ID from Azure CLI
    AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-$(az account show --query id -o tsv 2>/dev/null || echo "subscription-$(generate_random 8)")}
    AZURE_TENANT_ID=${AZURE_TENANT_ID:-$(az account show --query tenantId -o tsv 2>/dev/null || echo "tenant-$(generate_random 8)")}
    AZURE_CLIENT_ID=${AZURE_CLIENT_ID:-"client-$(generate_random 8)"}
    AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET:-"secret-$(generate_random 16)"}
    ENVIRONMENT=${ENVIRONMENT:-"dev"}
    REGION=${REGION:-"swedencentral"}
    RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-"rg-terraform-$(generate_random 8)"}

    # Export as Terraform variables
    export TF_VAR_azure_subscription_id=$AZURE_SUBSCRIPTION_ID
    export TF_VAR_azure_tenant_id=$AZURE_TENANT_ID
    export TF_VAR_azure_client_id=$AZURE_CLIENT_ID
    export TF_VAR_azure_client_secret=$AZURE_CLIENT_SECRET
    export TF_VAR_environment=$ENVIRONMENT
    export TF_VAR_region=$REGION
    export TF_VAR_resource_group_name=$RESOURCE_GROUP_NAME
}

# Load from .env if it exists
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Set default values for any missing variables
set_default_values

# Execute Terraform command
terraform "$@"

