# PostgreSQL Users Configuration - Direct Terraform Apply Approach
# Users are created directly on terraform apply without Git workflows or Azure Functions

locals {
  postgresql_users = {
    "shreyansh_user" = {
      privileges = "readwrite"
      description = "Shreyansh user addition"
    }
    "vikram_patel" = {
      privileges = "readwrite"
      description = "Vikram Patel user addition"
    }
    "nandini_vyas" = {
      privileges = "readonly"
      description = "Nandini Vyas user addition"
    }
  }
}

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
      echo "============================================="
      echo "Processing PostgreSQL user: ${each.key}"
      echo "Privileges: ${each.value.privileges}"
      echo "Description: ${each.value.description}"
      echo "============================================="
      
      # Initialize status tracking variables
      CONNECTION_SUCCESS=false
      USER_CREATED=false
      PASSWORD_UPDATED=false
      PRIVILEGES_GRANTED=false
      USER_VERIFIED=false
      
      # Check if psql is installed
      if ! command -v psql >/dev/null 2>&1; then
        echo "ERROR: psql (PostgreSQL client) is not installed"
        echo "Please install it:"
        echo "  Ubuntu/Debian: sudo apt-get install postgresql-client"
        echo "  RHEL/CentOS: sudo yum install postgresql"
        echo "  macOS: brew install postgresql"
        echo "Skipping user '${each.key}' due to missing psql client"
        exit 0  # Continue with next user
      fi
      
      # Set PostgreSQL connection parameters
      export PGHOST="${azurerm_postgresql_flexible_server.my-server.fqdn}"
      export PGPORT="5432"
      export PGDATABASE="${var.database_name}"
      export PGUSER="${var.postgre_admin_login}"
      export PGPASSWORD="${var.postgre_admin_password}"
      export PGSSLMODE="require"
      
      echo "Connecting to PostgreSQL server..."
      echo "Host: $PGHOST"
      echo "Database: $PGDATABASE"
      echo "User: $PGUSER"
      
      # Test connection with retry logic
      MAX_RETRIES=5
      RETRY_COUNT=0
      
      while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if psql -c "SELECT version();" >/dev/null 2>&1; then
          echo "PostgreSQL connection successful"
          CONNECTION_SUCCESS=true
          break
        else
          RETRY_COUNT=$((RETRY_COUNT + 1))
          echo "Connection attempt $RETRY_COUNT/$MAX_RETRIES failed, retrying in 10 seconds..."
          sleep 10
        fi
      done
      
      if [ "$CONNECTION_SUCCESS" = "false" ]; then
        echo "Failed to connect to PostgreSQL after $MAX_RETRIES attempts"
        echo "Please check:"
        echo "1. PostgreSQL server is running and accessible"
        echo "2. Firewall rules allow access from your IP: $(curl -s https://api.ipify.org)"
        echo "3. Admin credentials are correct"
        echo "Skipping user '${each.key}' due to connection failure"
        exit 0  # Continue with next user
      fi
      
      # Check if user already exists (preserves existing users)
      USER_EXISTS=$(psql -tAc "SELECT 1 FROM pg_user WHERE usename = '${each.key}';" 2>/dev/null)
      
      if [ "$USER_EXISTS" = "1" ]; then
        echo "User '${each.key}' already exists - preserving existing user"
        echo "Updating password and ensuring correct privileges..."
        USER_CREATED=true  # User already exists, so consider it "created"
        
        # Update password for existing user
        if psql -c "ALTER USER \"${each.key}\" WITH PASSWORD '${random_password.user_passwords[each.key].result}';" >/dev/null 2>&1; then
          echo "Password updated for existing user '${each.key}'"
          PASSWORD_UPDATED=true
        else
          echo "Failed to update password for user '${each.key}', continuing anyway"
        fi
      else
        echo "Creating new user '${each.key}'..."
        
        # Create new user with password
        if psql -c "CREATE USER \"${each.key}\" WITH PASSWORD '${random_password.user_passwords[each.key].result}';" >/dev/null 2>&1; then
          echo "User '${each.key}' created successfully"
          USER_CREATED=true
          PASSWORD_UPDATED=true
        else
          echo "Failed to create user '${each.key}', skipping privilege grants"
        fi
      fi
      
      # Only proceed with privileges if user creation/update was successful
      if [ "$USER_CREATED" = "true" ]; then
        echo "Applying '${each.value.privileges}' privileges to user '${each.key}'..."
        
        case "${each.value.privileges}" in
          "readonly")
            # Grant read-only access
            if psql -c "GRANT CONNECT ON DATABASE \"${var.database_name}\" TO \"${each.key}\";" >/dev/null 2>&1 && \
               psql -c "GRANT USAGE ON SCHEMA public TO \"${each.key}\";" >/dev/null 2>&1 && \
               psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"${each.key}\";" >/dev/null 2>&1 && \
               psql -c "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO \"${each.key}\";" >/dev/null 2>&1 && \
               psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO \"${each.key}\";" >/dev/null 2>&1 && \
               psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO \"${each.key}\";" >/dev/null 2>&1; then
              echo "Read-only privileges granted to '${each.key}'"
              PRIVILEGES_GRANTED=true
            else
              echo "Failed to grant some read-only privileges to '${each.key}'"
            fi
            ;;
          "readwrite")
            # Grant read-write access
            if psql -c "GRANT CONNECT ON DATABASE \"${var.database_name}\" TO \"${each.key}\";" >/dev/null 2>&1 && \
               psql -c "GRANT USAGE ON SCHEMA public TO \"${each.key}\";" >/dev/null 2>&1 && \
               psql -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"${each.key}\";" >/dev/null 2>&1 && \
               psql -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"${each.key}\";" >/dev/null 2>&1 && \
               psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO \"${each.key}\";" >/dev/null 2>&1 && \
               psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO \"${each.key}\";" >/dev/null 2>&1; then
              echo "Read-write privileges granted to '${each.key}'"
              PRIVILEGES_GRANTED=true
            else
              echo "Failed to grant some read-write privileges to '${each.key}'"
            fi
            ;;
          "full")
            # Grant full administrative access
            if psql -c "GRANT ALL PRIVILEGES ON DATABASE \"${var.database_name}\" TO \"${each.key}\";" >/dev/null 2>&1 && \
               psql -c "ALTER USER \"${each.key}\" WITH CREATEDB CREATEROLE;" >/dev/null 2>&1; then
              echo "Full administrative privileges granted to '${each.key}'"
              PRIVILEGES_GRANTED=true
            else
              echo "Failed to grant some full privileges to '${each.key}'"
            fi
            ;;
          *)
            echo "Unknown privilege type: ${each.value.privileges}"
            echo "Granting basic connect privileges only"
            if psql -c "GRANT CONNECT ON DATABASE \"${var.database_name}\" TO \"${each.key}\";" >/dev/null 2>&1; then
              PRIVILEGES_GRANTED=true
            fi
            ;;
        esac
      else
        echo "Skipping privilege grants for '${each.key}' due to user creation failure"
      fi
      
      # Verify user creation and privileges (only if user was created)
      if [ "$USER_CREATED" = "true" ]; then
        echo "Verifying user '${each.key}' setup..."
        USER_INFO=$(psql -tAc "SELECT usename, usecreatedb, usesuper FROM pg_user WHERE usename = '${each.key}';" 2>/dev/null)
        
        if [ -n "$USER_INFO" ]; then
          echo "User '${each.key}' verified successfully"
          echo "   User details: $USER_INFO"
          echo "   Password stored in Key Vault: ${azurerm_key_vault.user_passwords.name}"
          echo "   Secret name: pg-user-${replace(each.key, "_", "-")}-password"
          USER_VERIFIED=true
        else
          echo "Failed to verify user '${each.key}'"
        fi
      fi
      
      # Final status summary
      echo ""
      echo "Final status for user '${each.key}':"
      echo "   Connection: $([ "$CONNECTION_SUCCESS" = "true" ] && echo "Success" || echo "Failed")"
      echo "   User Created: $([ "$USER_CREATED" = "true" ] && echo "Success" || echo "Failed")"
      echo "   Password Set: $([ "$PASSWORD_UPDATED" = "true" ] && echo "Success" || echo "Skipped/Failed")"
      echo "   Privileges: $([ "$PRIVILEGES_GRANTED" = "true" ] && echo "Success" || echo "Skipped/Failed")"
      echo "   Verification: $([ "$USER_VERIFIED" = "true" ] && echo "Success" || echo "Skipped/Failed")"
      
      if [ "$USER_CREATED" = "true" ] && [ "$PRIVILEGES_GRANTED" = "true" ]; then
        echo "User '${each.key}' setup completed successfully!"
      else
        echo "User '${each.key}' setup completed with some issues - check logs above"
      fi
      
      echo ""
      echo "Continuing to next user..."
      
      # Always exit successfully so Terraform continues with next user
      exit 0
    EOT
  }
  
  # Triggers determine when to recreate the resource
  triggers = {
    # Recreate if user config changes
    user_config = jsonencode(each.value)
    
    # Recreate if password changes
    password_id = random_password.user_passwords[each.key].id
    
    # Recreate if server changes
    server_fqdn = azurerm_postgresql_flexible_server.my-server.fqdn
    
    # Daily recreation to ensure privileges are up-to-date
    # Remove this line if you don't want daily updates
    daily_check = formatdate("YYYY-MM-DD", timestamp())
  }
  
  depends_on = [
    time_sleep.wait_for_db,
    azurerm_key_vault_secret.user_passwords,
    random_password.user_passwords
  ]
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

