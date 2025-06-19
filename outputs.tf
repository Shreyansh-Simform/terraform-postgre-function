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

output "postgresql_server_version" {
  description = "Version of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.my-server.version
}

# Network Information
output "terraform_client_ip" {
  description = "Current IP address that has access to PostgreSQL"
  value       = chomp(data.http.my_ip.response_body)
}

# Key Vault Information
output "key_vault_name" {
  description = "Name of the Key Vault storing PostgreSQL user passwords"
  value       = azurerm_key_vault.user_passwords.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault storing PostgreSQL user passwords"
  value       = azurerm_key_vault.user_passwords.vault_uri
}

output "key_vault_auth_model" {
  description = "Authentication model used by Key Vault"
  value       = "RBAC"
}

# RBAC Information
output "rbac_assignments" {
  description = "RBAC role assignments for Key Vault access"
  value = {
    terraform_principal = {
      role = "Key Vault Secrets Officer"
      scope = azurerm_key_vault.user_passwords.name
      principal_id = data.azurerm_client_config.current.object_id
    }
  }
}

# User Management Information
output "user_management_info" {
  description = "PostgreSQL user management information"
  value = {
    total_users_managed = length(local.postgresql_users)
    users_list = keys(local.postgresql_users)
    key_vault_name = azurerm_key_vault.user_passwords.name
    postgresql_server = azurerm_postgresql_flexible_server.my-server.fqdn
    management_method = "Direct psql commands on terraform apply"
    
    # Example commands for password retrieval
    password_retrieval_examples = {
      for username in keys(local.postgresql_users) :
      username => "az keyvault secret show --vault-name ${azurerm_key_vault.user_passwords.name} --name pg-user-${replace(username, "_", "-")}-password --query value -o tsv"
    }
  }
  
  sensitive = false
}

# Created Users Summary
output "created_users_summary" {
  description = "Summary of created PostgreSQL users and their privileges"
  value = {
    for username, config in local.postgresql_users : username => {
      privileges = config.privileges
      description = config.description
      password_secret_name = "pg-user-${replace(username, "_", "-")}-password"
    }
  }
}

# Password Retrieval Commands
output "password_retrieval_commands" {
  description = "Commands to retrieve PostgreSQL user passwords from Key Vault"
  value = {
    for username in keys(local.postgresql_users) : username => 
    "az keyvault secret show --vault-name ${azurerm_key_vault.user_passwords.name} --name pg-user-${replace(username, "_", "-")}-password --query 'value' -o tsv"
  }
}

# Complete User Management Instructions
output "user_management_instructions" {
  description = "Complete instructions for managing PostgreSQL users with direct Terraform approach"
  value = <<-EOT
PostgreSQL User Management with Direct Terraform Apply:

CURRENT CONFIGURATION:
- PostgreSQL Server: ${azurerm_postgresql_flexible_server.my-server.fqdn}
- Database: ${azurerm_postgresql_flexible_server_database.my-postgre-db.name}
- Key Vault: ${azurerm_key_vault.user_passwords.name}
- Authentication: RBAC (no access policies)
- Management Method: Direct psql commands

AUTOMATICALLY CREATED USERS:
${join("\n", [for username, config in local.postgresql_users : "   - ${username}: ${config.privileges} privileges (${config.description})"])}

DEPLOYMENT COMMAND:
   terraform apply -var-file="terraform.tfvars" -var-file="secret.tfvars"
   
   This command will:
   - Deploy PostgreSQL Flexible Server with public access
   - Create Key Vault with RBAC authorization
   - Generate secure passwords for all users
   - Store passwords in Key Vault
   - Create PostgreSQL users directly via psql
   - Handle individual user failures gracefully

ADDING NEW USERS:
1. Edit users.tf and add new user to postgresql_users local block:
   "new_user" = {
     privileges = "readwrite"  # readonly, readwrite, or full
     description = "Description of user purpose"
   }
2. Run: terraform apply -var-file="terraform.tfvars" -var-file="secret.tfvars"
3. New user will be created automatically with secure password

PASSWORD RETRIEVAL:
Get specific user password:
   az keyvault secret show --vault-name ${azurerm_key_vault.user_passwords.name} --name pg-user-USERNAME-password --query 'value' -o tsv

List all PostgreSQL user passwords:
   az keyvault secret list --vault-name ${azurerm_key_vault.user_passwords.name} --query '[?contains(name, `pg-user`)].{Name:name, Username:tags.Username, Privileges:tags.Privileges}' -o table

DIRECT DATABASE CONNECTION:
Host: ${azurerm_postgresql_flexible_server.my-server.fqdn}
Port: 5432
Database: ${azurerm_postgresql_flexible_server_database.my-postgre-db.name}
SSL Mode: require

FEATURES:
- Incremental user creation (new users added, existing preserved)
- Individual failure handling (one user failure doesn't stop others)
- RBAC security model for Key Vault access
- Automatic IP firewall management for Terraform client
- Secure password generation and storage

PREREQUISITES:
- PostgreSQL client (psql) installed on Terraform execution environment
- Azure CLI authenticated with appropriate permissions
- Network access to PostgreSQL server (automatically configured)
  EOT
}

# Connection Information for Applications
output "connection_info" {
  description = "Database connection information for applications"
  value = {
    server_fqdn = azurerm_postgresql_flexible_server.my-server.fqdn
    database_name = azurerm_postgresql_flexible_server_database.my-postgre-db.name
    port = 5432
    ssl_mode = "require"
    key_vault_name = azurerm_key_vault.user_passwords.name
    note = "Retrieve user passwords from Key Vault using the password_retrieval_commands output"
  }
  sensitive = false
}