# PostgreSQL Users Management - Direct Terraform Apply Approach
# Users are created directly on terraform apply without Git workflows or Azure Functions
# User configurations are defined in users_config.tf

# Auto-generate secure passwords for each user
resource "random_password" "user_passwords" {
  for_each = local.postgresql_users
  
  length  = 20
  special = true
  upper   = true
  lower   = true
  numeric = true
  
  # Ensure password meets PostgreSQL and security requirements
  min_upper   = 3
  min_lower   = 3
  min_numeric = 3
  min_special = 2
  
  # Exclude potentially confusing characters
  override_special = "!@#$%^&*()-_=+[]{}|;:,.<>?"
  
  # Only regenerate if user config changes (prevents unnecessary password changes)
  keepers = {
    user_config = jsonencode(local.postgresql_users[each.key])
  }
}

# Store auto-generated passwords in Key Vault
resource "azurerm_key_vault_secret" "user_passwords" {
  for_each = local.postgresql_users
  
  name         = "pg-user-${replace(each.key, "_", "-")}-password"
  value        = random_password.user_passwords[each.key].result
  key_vault_id = azurerm_key_vault.user_passwords.id
  
  tags = {
    Username    = each.key
    Privileges  = each.value.privileges
    Description = each.value.description
    CreatedBy   = "Terraform-Direct"
  }
  
  depends_on = [
    azurerm_key_vault.user_passwords,
    time_sleep.wait_for_rbac_propagation
  ]
}

# Wait for PostgreSQL server to be ready and firewall rules to be applied
resource "time_sleep" "wait_for_db" {
  create_duration = "60s"
  depends_on = [
    azurerm_postgresql_flexible_server.my-server,
    azurerm_postgresql_flexible_server_database.my-postgre-db,
    azurerm_postgresql_flexible_server_firewall_rule.terraform_client
  ]
}

# Create PostgreSQL users using direct psql commands during terraform apply
resource "null_resource" "create_postgresql_users" {
  for_each = local.postgresql_users
  
  provisioner "local-exec" {
    command = <<-EOT
      export PGHOST="${azurerm_postgresql_flexible_server.my-server.fqdn}" PGDATABASE="${var.database_name}" PGUSER="${var.postgre_admin_login}" PGPASSWORD="${var.postgre_admin_password}"
      echo "Processing user: ${each.key} (${each.value.privileges})"
      psql -c "SELECT 1;" || { echo "Connection failed for ${each.key}"; exit 1; }
      psql -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '${each.key}') THEN CREATE USER \"${each.key}\" WITH PASSWORD '${random_password.user_passwords[each.key].result}'; END IF; ALTER USER \"${each.key}\" WITH PASSWORD '${random_password.user_passwords[each.key].result}'; GRANT CONNECT ON DATABASE \"${var.database_name}\" TO \"${each.key}\"; GRANT USAGE ON SCHEMA public TO \"${each.key}\"; END \$\$;" && echo "✅ User ${each.key} ready"
      case "${each.value.privileges}" in
        "readonly") psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"${each.key}\"; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO \"${each.key}\";" && echo "✅ Readonly applied" ;;
        "readwrite") psql -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"${each.key}\"; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO \"${each.key}\";" && echo "✅ Readwrite applied" ;;
        "full") psql -c "GRANT ALL PRIVILEGES ON DATABASE \"${var.database_name}\" TO \"${each.key}\"; GRANT ALL ON ALL TABLES IN SCHEMA public TO \"${each.key}\"; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO \"${each.key}\";" && echo "✅ Database admin granted"; psql -c "ALTER USER \"${each.key}\" WITH CREATEDB CREATEROLE;" && echo "✅ Full admin applied" || echo "⚠️ Partial admin" ;;
      esac
    EOT
  }
  
  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      export PGHOST="${self.triggers.server_fqdn}" PGDATABASE="${self.triggers.database_name}" PGUSER="${self.triggers.admin_login}" PGPASSWORD="${self.triggers.admin_password}"
      echo "ATTEMPTING TO DELETE USER: ${self.triggers.username}"
      if ! psql -c "SELECT 1;" 2>/dev/null; then
        echo "CRITICAL: Cannot connect to PostgreSQL - FAILING DELETION"
        exit 1
      fi
      USER_EXISTS=$(psql -t -c "SELECT COUNT(*) FROM pg_user WHERE usename = '${self.triggers.username}';")
      if [ "$USER_EXISTS" -eq 0 ]; then
        echo "User ${self.triggers.username} does not exist - nothing to delete"
        exit 0
      fi
      psql -t -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public';" | while read table; do
        if [ -n "$table" ]; then
          psql -c "REVOKE ALL ON TABLE \"$table\" FROM \"${self.triggers.username}\";" 2>/dev/null || echo "Could not revoke privileges on table $table"
        fi
      done
      psql -c "REVOKE ALL PRIVILEGES ON DATABASE \"${self.triggers.database_name}\" FROM \"${self.triggers.username}\";" 2>/dev/null || echo "Database privilege revocation failed"
      psql -c "REVOKE ALL ON SCHEMA public FROM \"${self.triggers.username}\";" 2>/dev/null || echo "Schema privilege revocation failed"
      psql -c "REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM \"${self.triggers.username}\";" 2>/dev/null || echo "Sequence privilege revocation failed"
      psql -c "REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM \"${self.triggers.username}\";" 2>/dev/null || echo "Function privilege revocation failed"
      psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM \"${self.triggers.username}\";" 2>/dev/null || echo "Default privilege cleanup failed (expected for some users)"
      if psql -c "DROP USER \"${self.triggers.username}\";"; then
        echo "SUCCESS: User ${self.triggers.username} successfully deleted from PostgreSQL"
      else
        echo "CRITICAL: Failed to drop user ${self.triggers.username}"
        psql -c "SELECT grantee, table_name, privilege_type FROM information_schema.role_table_grants WHERE grantee = '${self.triggers.username}';" || echo "Could not check table privileges"
        exit 1
      fi
    EOT
    on_failure = fail
  }
  
  triggers = { 
    user_config = jsonencode(each.value)
    username = each.key
    server_fqdn = azurerm_postgresql_flexible_server.my-server.fqdn
    database_name = var.database_name
    admin_login = var.postgre_admin_login
    admin_password = var.postgre_admin_password
  }
  depends_on = [time_sleep.wait_for_db, azurerm_key_vault_secret.user_passwords]
}

# Create a comprehensive summary of all users for easy reference
resource "azurerm_key_vault_secret" "users_summary" {
  name         = "pg-users-summary"
  key_vault_id = azurerm_key_vault.user_passwords.id
  
  value = jsonencode({
    created_at = timestamp()
    total_users = length(local.postgresql_users)
    users = {
      for username, config in local.postgresql_users : username => {
        privileges = config.privileges
        description = config.description
        password_secret_name = "pg-user-${replace(username, "_", "-")}-password"
      }
    }
    postgresql_server = azurerm_postgresql_flexible_server.my-server.fqdn
    database_name = var.database_name
    key_vault_name = azurerm_key_vault.user_passwords.name
    management_approach = "Direct-Terraform-Apply"
  })
  
  depends_on = [
    azurerm_key_vault_secret.user_passwords, 
    null_resource.create_postgresql_users
  ]
}

