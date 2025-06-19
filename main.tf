# This Terraform configuration sets up an Azure PostgreSQL Flexible Server with direct user management
# Users are created directly via psql commands during terraform apply

//Local Variables
locals {

    rg_name = "${var.business_unit}-${var.environment}-${var.resource_group_name}"
}
#Resource Group Block to contain the resources.
resource "azurerm_resource_group" "myrg" {
  name     = local.rg_name
  location = var.resource_group_location
}

resource "azurerm_postgresql_flexible_server" "my-server" {
  name                          = var.postgresql_flexible_server_name
  resource_group_name           = azurerm_resource_group.myrg.name
  location                      = azurerm_resource_group.myrg.location
  version                       = var.postgresql_flexible_server_version
  public_network_access_enabled = var.public_network_access_enabled
  administrator_login           = var.postgre_admin_login
  administrator_password        = var.postgre_admin_password
  zone                          = var.postgre_sql_serverzone

  storage_mb   = var.postgresql_flexible_server_storage_size
  sku_name     = var.postgresql_flexible_server_sku_name
  
  lifecycle {
    prevent_destroy = true
  }
}

# Add firewall rule to allow Azure services when using public access
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.my-server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Add firewall rule for your current IP (for terraform execution)
# Get your current IP automatically
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "terraform_client" {
  name             = "terraform-client-access"
  server_id        = azurerm_postgresql_flexible_server.my-server.id
  start_ip_address = chomp(data.http.my_ip.response_body)
  end_ip_address   = chomp(data.http.my_ip.response_body)
}

resource "azurerm_postgresql_flexible_server_database" "my-postgre-db" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.my-server.id
  charset   = "UTF8"
  collation = "en_US.utf8"
  lifecycle {
    prevent_destroy = true
  }
}

# Key Vault for storing auto-generated PostgreSQL user passwords
data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create Key Vault for password storage with RBAC authorization
resource "azurerm_key_vault" "user_passwords" {
  name                = "kv-pg-users-${random_string.suffix.result}"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Enable RBAC authorization instead of access policies
  enable_rbac_authorization = true

  # Enable soft delete and purge protection for production
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = {
    Environment = var.environment
    Purpose     = "PostgreSQL User Password Storage"
    AuthModel   = "RBAC"
  }
}

# Grant Key Vault Secrets Officer role to current user/service principal for full secret management
resource "azurerm_role_assignment" "terraform_kv_secrets_officer" {
  scope                = azurerm_key_vault.user_passwords.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  description          = "Terraform automation access for PostgreSQL user password management"
}

# Wait for RBAC role assignment to propagate before creating secrets
resource "time_sleep" "wait_for_rbac_propagation" {
  create_duration = "60s"
  
  depends_on = [
    azurerm_role_assignment.terraform_kv_secrets_officer
  ]
  
  triggers = {
    role_assignment_id = azurerm_role_assignment.terraform_kv_secrets_officer.id
  }
}



