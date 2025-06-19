# PostgreSQL Users Configuration with Auto-Generated Passwords
# This file defines PostgreSQL users that will be created automatically
# with secure passwords stored in Azure Key Vault

locals {
  postgresql_users = {
    "analytics_user" = {
      privileges = "readonly"
      description = "User for analytics and reporting queries"
    }
    "app_backend_user" = {
      privileges = "readwrite"
      description = "Backend application database user"
    }
    "admin_user" = {
      privileges = "full"
      description = "Database administrator user"
    }
    "reporting_user" = {
      privileges = "readonly"
      description = "Read-only user for business intelligence tools"
    }
    "api_service_user" = {
      privileges = "readwrite"
      description = "API service database user"
    }
     "shreyansh_user" = {
      privileges = "readwrite"
      description = "Shreyansh user addition"
    }
     "vikram_patel" = {
      privileges = "readwrite"
      description = "Vikram Patel user addition"
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
}

# Store auto-generated passwords in Key Vault
resource "azurerm_key_vault_secret" "user_passwords" {
  for_each = local.postgresql_users
  
  # Replace underscores with dashes for Key Vault naming requirements
  name         = "pg-user-${replace(each.key, "_", "-")}-password"
  value        = random_password.user_passwords[each.key].result
  key_vault_id = azurerm_key_vault.user_passwords.id
  
  tags = {
    Username    = each.key
    Privileges  = each.value.privileges
    Description = each.value.description
    CreatedBy   = "Terraform"
  }
  
  depends_on = [azurerm_key_vault.user_passwords]
}

# Get function key for API authentication
data "external" "function_key" {
  program = ["bash", "-c", <<-EOT
    FUNCTION_KEY=$(az functionapp keys list \
      --name ${azurerm_linux_function_app.user_creator_func.name} \
      --resource-group ${azurerm_resource_group.myrg.name} \
      --query 'functionKeys.default' -o tsv 2>/dev/null)
    
    if [ -z "$FUNCTION_KEY" ]; then
      echo '{"error": "Failed to get function key"}'
      exit 1
    fi
    
    echo "{\"function_key\": \"$FUNCTION_KEY\"}"
  EOT
  ]
  
  depends_on = [null_resource.deploy_function_code]
}

# Create PostgreSQL users using direct API calls (no script dependency)
# Users will be created sequentially to avoid concurrency issues
resource "null_resource" "create_postgresql_users" {
  for_each = local.postgresql_users
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Creating PostgreSQL user: ${each.key} with ${each.value.privileges} privileges"
      echo "Description: ${each.value.description}"
      
      # Wait for function to be ready and add jitter to avoid conflicts
      WAIT_TIME=$((10 + RANDOM % 10))
      echo "Waiting $WAIT_TIME seconds before creating user..."
      sleep $WAIT_TIME
      
      # Get function endpoint and key
      FUNCTION_URL="https://${azurerm_linux_function_app.user_creator_func.default_hostname}/api/create-user"
      FUNCTION_KEY="${data.external.function_key.result.function_key}"
      
      # Retry logic for user creation
      MAX_RETRIES=3
      RETRY_COUNT=0
      
      while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        echo "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES to create user ${each.key}"
        
        # Create user via direct API call
        HTTP_STATUS=$(curl -s -o /tmp/response_body_${each.key}.txt -w "%%{http_code}" \
          -X POST "$FUNCTION_URL?code=$FUNCTION_KEY" \
          -H "Content-Type: application/json" \
          -d "{
            \"username\": \"${each.key}\",
            \"password\": \"${random_password.user_passwords[each.key].result}\",
            \"privileges\": \"${each.value.privileges}\"
          }")
        
        # Read response body
        RESPONSE_BODY=$(cat /tmp/response_body_${each.key}.txt 2>/dev/null || echo "No response body")
        
        if [ "$HTTP_STATUS" -eq 201 ]; then
          echo "User '${each.key}' created successfully with '${each.value.privileges}' privileges"
          echo "Password stored in Key Vault: ${azurerm_key_vault.user_passwords.name}"
          echo "Response: $RESPONSE_BODY"
          break
        elif [ "$HTTP_STATUS" -eq 409 ]; then
          echo "User '${each.key}' already exists"
          echo "Response: $RESPONSE_BODY"
          break
        elif [ "$HTTP_STATUS" -eq 500 ] && echo "$RESPONSE_BODY" | grep -q "concurrently updated"; then
          echo "  Concurrency conflict detected for user '${each.key}'. Retrying..."
          RETRY_COUNT=$((RETRY_COUNT + 1))
          if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            SLEEP_TIME=$((5 + RANDOM % 10))
            echo " Waiting $SLEEP_TIME seconds before retry..."
            sleep $SLEEP_TIME
          fi
        else
          echo " Failed to create user '${each.key}'. HTTP Status: $HTTP_STATUS"
          echo " Response: $RESPONSE_BODY"
          echo "Function URL: $FUNCTION_URL"
          rm -f /tmp/response_body_${each.key}.txt
          exit 1
        fi
      done
      
      if [ $RETRY_COUNT -eq $MAX_RETRIES ] && [ "$HTTP_STATUS" -ne 201 ] && [ "$HTTP_STATUS" -ne 409 ]; then
        echo "Failed to create user '${each.key}' after $MAX_RETRIES attempts"
        echo "Last response: $RESPONSE_BODY"
        rm -f /tmp/response_body_${each.key}.txt
        exit 1
      fi
      
      # Clean up temp file
      rm -f /tmp/response_body_${each.key}.txt
    EOT
  }
  
  depends_on = [
    null_resource.deploy_function_code,
    azurerm_key_vault_secret.user_passwords,
    data.external.function_key
  ]
  
  triggers = {
    user_config     = jsonencode(each.value)
    password        = random_password.user_passwords[each.key].result
    function_ready  = null_resource.deploy_function_code.id
    function_key    = data.external.function_key.result.function_key
  }
}

# Store user information summary in Key Vault for easy reference
resource "azurerm_key_vault_secret" "users_summary" {
  name         = "pg-users-summary"
  key_vault_id = azurerm_key_vault.user_passwords.id
  
  value = jsonencode({
    created_at = timestamp()
    users = {
      for username, config in local.postgresql_users : username => {
        privileges = config.privileges
        description = config.description
        # Use consistent naming with dashes for secret reference
        password_secret_name = "pg-user-${replace(username, "_", "-")}-password"
      }
    }
    total_users = length(local.postgresql_users)
    key_vault_name = azurerm_key_vault.user_passwords.name
    function_app_name = azurerm_linux_function_app.user_creator_func.name
  })
  
  depends_on = [azurerm_key_vault_secret.user_passwords, null_resource.create_postgresql_users]
}