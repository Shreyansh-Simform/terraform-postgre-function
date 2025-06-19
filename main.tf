# This Terraform configuration sets up an Azure PostgreSQL Flexible Server with a private DNS zone and subnet delegation.

#Resource Group Block to containe the resources.
resource "azurerm_resource_group" "myrg" {
  name     = local.rg_name
  location = var.resource_group_location
}

/*

#Virtual Network for PostgreSQL Flexible Server
resource "azurerm_virtual_network" "myvnet" {
  name                = local.vnet_name
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  address_space       = var.virtual_network_address_space
  
}


# VNet Integration Components - Commented out for Consumption Plan (Y1) compatibility
# Uncomment these when using Premium plans (EP1/P1v2) with private PostgreSQL

#Delegated Subnet for PostgreSQL Flexible Server
resource "azurerm_subnet" "mysubnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["10.0.2.0/24"]
  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

#Delegated Subnet for Function App VNet Integration
resource "azurerm_subnet" "function_subnet" {
  name                 = "function-subnet"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["10.0.3.0/24"]
  
  delegation {
    name = "webapp-delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "pvt-dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.myrg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "my-pvt-dns-link" {
  name                  = "PostgreVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.pvt-dns.name
  virtual_network_id    = azurerm_virtual_network.myvnet.id
  resource_group_name   = azurerm_resource_group.myrg.name
  depends_on            = [azurerm_subnet.mysubnet]
}
*/

resource "azurerm_postgresql_flexible_server" "my-server" {
  name                          = var.postgresql_flexible_server_name
  resource_group_name           = azurerm_resource_group.myrg.name
  location                      = azurerm_resource_group.myrg.location
  version                       = var.postgresql_flexible_server_version
  # delegated_subnet_id           = azurerm_subnet.mysubnet.id           # Commented out for public access
  # private_dns_zone_id           = azurerm_private_dns_zone.pvt-dns.id   # Commented out for public access
  public_network_access_enabled = var.public_network_access_enabled
  administrator_login           = var.postgre_admin_login
  administrator_password        = var.postgre_admin_password
  zone                          = var.postgre_sql_serverzone

  storage_mb   = var.postgresql_flexible_server_storage_size

  sku_name   = var.postgresql_flexible_server_sku_name
  # depends_on = [azurerm_private_dns_zone_virtual_network_link.my-pvt-dns-link]  # Commented out for public access
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

resource "azurerm_postgresql_flexible_server_database" "my-postgre-db" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.my-server.id
  charset   = "UTF8"
  collation = "en_US.utf8"
  lifecycle {
    prevent_destroy = true
  }

}

# Automatically zip the function code
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/pg_user_function"
  output_path = "${path.module}/pg_user_function.zip"
  
  # Terraform tracks file changes automatically
}

resource "azurerm_storage_account" "funcstorage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.myrg.name
  location                 = azurerm_resource_group.myrg.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

}

resource "azurerm_storage_container" "func_container" {
  name                  = var.storage_container_name
  storage_account_name  = azurerm_storage_account.funcstorage.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "function_zip" {
  name                   = var.storage_blob_name
  storage_account_name   = azurerm_storage_account.funcstorage.name
  storage_container_name = azurerm_storage_container.func_container.name
  type                   = "Block"
  source                 = data.archive_file.function_zip.output_path
}

resource "azurerm_service_plan" "funcplan" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.myrg.name
  location            = azurerm_resource_group.myrg.location
  os_type             = var.service_plan_os_type
  sku_name            = var.service_plan_sku_name
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_linux_function_app" "user_creator_func" {
  name                = var.function_app_name
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  service_plan_id     = azurerm_service_plan.funcplan.id

  storage_account_name       = azurerm_storage_account.funcstorage.name
  storage_account_access_key = azurerm_storage_account.funcstorage.primary_access_key
  lifecycle {
    prevent_destroy = true 
  }

  # Enable system-assigned managed identity for Key Vault access
  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "AzureWebJobsStorage"      = azurerm_storage_account.funcstorage.primary_connection_string

    # PostgreSQL DB connection variables (now using public endpoint)
    "PGHOST"     = azurerm_postgresql_flexible_server.my-server.fqdn
    "PGUSER"     = var.postgre_admin_login
    "PGPASSWORD" = var.postgre_admin_password
    "PGDATABASE" = var.database_name
    
    # Key Vault configuration for function app
    "KEY_VAULT_NAME" = azurerm_key_vault.user_passwords.name
    "KEY_VAULT_URI"  = azurerm_key_vault.user_passwords.vault_uri
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }

  # Remove dependencies on storage blob since we're not using WEBSITE_RUN_FROM_PACKAGE
}

# Phase 2: Function deployment via Azure CLI
resource "null_resource" "deploy_function_code" {
  provisioner "local-exec" {
    command = <<-EOT
      echo " Starting function code deployment..."
      
      # Wait for function app to be fully ready
      echo " Waiting for function app to initialize..."
      sleep 30
      
      # Deploy function code using Azure CLI
      echo "Deploying function package..."
      az functionapp deployment source config-zip \
        --name ${azurerm_linux_function_app.user_creator_func.name} \
        --resource-group ${azurerm_resource_group.myrg.name} \
        --src ${data.archive_file.function_zip.output_path} \
        --build-remote true \
        --timeout 300
      
      # Wait for deployment to complete
      echo " Waiting for deployment to complete..."
      sleep 60
      
      # Verify function deployment
      echo " Verifying function deployment..."
      az functionapp function list \
        --name ${azurerm_linux_function_app.user_creator_func.name} \
        --resource-group ${azurerm_resource_group.myrg.name} \
        --output table
      
      echo " Function deployment completed!"
    EOT
  }
  
  depends_on = [azurerm_linux_function_app.user_creator_func]
  
  # Redeploy if function code changes or function app changes
  triggers = {
    function_code_hash = data.archive_file.function_zip.output_md5
    function_app_id    = azurerm_linux_function_app.user_creator_func.id
  }
}

# Key Vault for storing auto-generated PostgreSQL user passwords
data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create Key Vault first without Function App access policy
resource "azurerm_key_vault" "user_passwords" {
  name                = "kv-pg-users-${random_string.suffix.result}"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Enable soft delete and purge protection for production
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Only allow your current user/service principal to manage secrets initially
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "Set", "List", "Delete", "Backup", "Restore", "Recover", "Purge"
    ]
  }

  tags = {
    Environment = var.environment
    Purpose     = "PostgreSQL User Password Storage"
  }
}

resource "azurerm_key_vault_access_policy" "function_app_access" {
  key_vault_id = azurerm_key_vault.user_passwords.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_function_app.user_creator_func.identity[0].principal_id

  secret_permissions = [
    "Get", "Set", "List"
  ]

  depends_on = [azurerm_linux_function_app.user_creator_func]
}



