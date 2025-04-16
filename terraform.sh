#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
    
    # Convert environment variables to Terraform variables
    export TF_VAR_region=$AZURE_REGION
    export TF_VAR_azure_subscription_id=$AZURE_SUBSCRIPTION_ID
    export TF_VAR_azure_tenant_id=$AZURE_TENANT_ID
    export TF_VAR_azure_client_id=$AZURE_CLIENT_ID
    export TF_VAR_azure_client_secret=$AZURE_CLIENT_SECRET
    export TF_VAR_environment=$ENVIRONMENT
    export TF_VAR_resource_group_name=$RESOURCE_GROUP_NAME
    export TF_VAR_sql_admin_login=$SQL_ADMIN_LOGIN
fi

# Execute Terraform command
terraform "$@"