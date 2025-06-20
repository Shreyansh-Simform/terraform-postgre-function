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
PostgreSQL User Management - Direct Terraform Apply

CONFIG: ${azurerm_postgresql_flexible_server.my-server.fqdn} | ${azurerm_key_vault.user_passwords.name} | RBAC Auth

USERS: ${join(", ", [for username, config in local.postgresql_users : "${username}(${config.privileges})"])}

DEPLOY: terraform apply -var-file="terraform.tfvars" -var-file="secret.tfvars"

ADD USER: 
1. Edit users.tf: "new_user" = { privileges = "readwrite", description = "..." }
2. Run: terraform apply

GET PASSWORD: az keyvault secret show --vault-name ${azurerm_key_vault.user_passwords.name} --name pg-user-USERNAME-password --query 'value' -o tsv

CONNECT: Host=${azurerm_postgresql_flexible_server.my-server.fqdn} DB=${azurerm_postgresql_flexible_server_database.my-postgre-db.name} Port=5432 SSL=require

FEATURES: Incremental creation, failure handling, RBAC security, auto passwords
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