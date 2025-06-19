# Infrastructure Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.myrg.name
}

# PostgreSQL Server Information
output "postgresql_server_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.my-server.fqdn
}

output "postgresql_database_name" {
  description = "Name of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.my-postgre-db.name
}

# Function App Information
output "function_app_name" {
  description = "Name of the Function App for user management"
  value       = azurerm_linux_function_app.user_creator_func.name
}

output "function_app_url" {
  description = "Base URL of the Function App"
  value       = "https://${azurerm_linux_function_app.user_creator_func.default_hostname}"
}

output "create_user_endpoint" {
  description = "Complete endpoint URL for creating PostgreSQL users"
  value       = "https://${azurerm_linux_function_app.user_creator_func.default_hostname}/api/create-user"
}

# Function Key Retrieval Commands
output "get_function_key_command" {
  description = "Azure CLI command to retrieve the function key for API access"
  value       = "az functionapp keys list --name ${azurerm_linux_function_app.user_creator_func.name} --resource-group ${azurerm_resource_group.myrg.name} --query 'functionKeys.default' -o tsv"
}

/*
# Network Information
output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.myvnet.name
}


# VNet Integration Outputs - Commented out for Consumption Plan (Y1) compatibility
# Uncomment these when using Premium plans (EP1/P1v2) with VNet integration

output "function_subnet_id" {
  description = "ID of the function app subnet"
  value       = azurerm_subnet.function_subnet.id
}
*/

# Service Plan Information
output "service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.funcplan.name
}

output "service_plan_sku" {
  description = "SKU of the App Service Plan"
  value       = azurerm_service_plan.funcplan.sku_name
}

# User Management Instructions (Function-Only Approach)
output "user_management_instructions" {
  description = "Instructions for managing PostgreSQL users via Function API"
  value = <<-EOT
    PostgreSQL User Management via Function API:
    
    1. Get Function Key:
       az functionapp keys list --name ${azurerm_linux_function_app.user_creator_func.name} --resource-group ${azurerm_resource_group.myrg.name} --query 'functionKeys.default' -o tsv
    
    2. Create User:
       curl -X POST "https://${azurerm_linux_function_app.user_creator_func.default_hostname}/api/create-user?code=FUNCTION_KEY" \
         -H "Content-Type: application/json" \
         -d '{"username":"new_user","password":"SecurePass123!","privileges":"readonly"}'
    
    3. Available privileges: "readonly", "readwrite", "full"
    
    4. Users are created instantly without any Terraform configuration changes.
    
    No more scaling issues - create unlimited users via API!
  EOT
}

# Key Vault outputs for password management
output "key_vault_name" {
  description = "Name of the Key Vault storing PostgreSQL user passwords"
  value       = azurerm_key_vault.user_passwords.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault storing PostgreSQL user passwords"
  value       = azurerm_key_vault.user_passwords.vault_uri
}

# Commands to retrieve passwords from Key Vault
output "password_retrieval_commands" {
  description = "Commands to retrieve PostgreSQL user passwords from Key Vault"
  value = {
    for username in keys(local.postgresql_users) : username => 
    "az keyvault secret show --vault-name ${azurerm_key_vault.user_passwords.name} --name pg-user-${replace(username, "_", "-")}-password --query 'value' -o tsv"
  }
}

# User summary information
output "created_users_summary" {
  description = "Summary of created PostgreSQL users and their privileges"
  value = {
    for username, config in local.postgresql_users : username => {
      privileges = config.privileges
      description = config.description
    }
  }
}

# Complete user management instructions - Pure Terraform approach
output "user_management_with_keyvault_instructions" {
  description = "Complete instructions for managing PostgreSQL users with Key Vault passwords - Pure Terraform"
  value = <<-EOT
PostgreSQL User Management with Azure Key Vault (Pure Terraform Approach):

🔐 AUTOMATICALLY CREATED USERS:
${join("\n", [for username, config in local.postgresql_users : "   - ${username}: ${config.privileges} (${config.description})"])}

🚀 DEPLOYMENT COMMAND:
   terraform apply -var-file="terraform.tfvars" -var-file="secret.tfvars"
   
   This single command will:
   ✅ Deploy all infrastructure (PostgreSQL, Function App, Key Vault)
   ✅ Generate secure passwords for all users
   ✅ Store passwords in Key Vault
   ✅ Create all PostgreSQL users automatically
   ✅ No external scripts required!

🔑 PASSWORD RETRIEVAL:
Get specific user password (note: underscores become dashes in secret names):
   az keyvault secret show --vault-name ${azurerm_key_vault.user_passwords.name} --name pg-user-USERNAME-password --query 'value' -o tsv

Examples:
   az keyvault secret show --vault-name ${azurerm_key_vault.user_passwords.name} --name pg-user-analytics-user-password --query 'value' -o tsv
   az keyvault secret show --vault-name ${azurerm_key_vault.user_passwords.name} --name pg-user-reporting-user-password --query 'value' -o tsv

Get all user passwords:
   az keyvault secret list --vault-name ${azurerm_key_vault.user_passwords.name} --query '[?contains(name, `pg-user`)].{Name:name, Username:tags.Username, Privileges:tags.Privileges}' -o table

📋 ADDING NEW USERS:
1. Edit users.tf file and add new user to postgresql_users local block
2. Run: terraform apply
3. New user will be created automatically with auto-generated password

🗂️ KEY VAULT: ${azurerm_key_vault.user_passwords.name}
🌐 VAULT URI: ${azurerm_key_vault.user_passwords.vault_uri}
🎯 FUNCTION APP: ${azurerm_linux_function_app.user_creator_func.name}

💡 Everything is managed through Terraform - no external scripts needed!
   Just edit users.tf and run 'terraform apply' to manage users.
  EOT
}