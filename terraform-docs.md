## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.4 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.80 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2.4 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.80 |
| <a name="provider_external"></a> [external](#provider\_external) | ~> 2.3 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.2 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.user_passwords](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_access_policy.function_app_access](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_secret.user_passwords](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.users_summary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_linux_function_app.user_creator_func](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_postgresql_flexible_server.my-server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_database.my-postgre-db](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.azure_services](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_resource_group.myrg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_service_plan.funcplan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.funcstorage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_blob.function_zip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob) | resource |
| [azurerm_storage_container.func_container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [null_resource.create_postgresql_users](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.deploy_function_code](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.user_passwords](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [archive_file.function_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [external_external.function_key](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_replication_type"></a> [account\_replication\_type](#input\_account\_replication\_type) | The replication type of the storage account. | `string` | `"LRS"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | The performance tier of the storage account. | `string` | `"Standard"` | no |
| <a name="input_app_service_plan_name"></a> [app\_service\_plan\_name](#input\_app\_service\_plan\_name) | The name of the App Service Plan. | `string` | n/a | yes |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | The business unit for which the resources are being created. | `string` | n/a | yes |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | The name of the PostgreSQL database to be created. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment for which the resources are being created (e.g., dev, test, prod). | `string` | n/a | yes |
| <a name="input_function_app_name"></a> [function\_app\_name](#input\_function\_app\_name) | The name of the Function App. | `string` | n/a | yes |
| <a name="input_postgre_admin_login"></a> [postgre\_admin\_login](#input\_postgre\_admin\_login) | The administrator login for the PostgreSQL Flexible Server. | `string` | n/a | yes |
| <a name="input_postgre_admin_password"></a> [postgre\_admin\_password](#input\_postgre\_admin\_password) | The administrator password for the PostgreSQL Flexible Server. | `string` | n/a | yes |
| <a name="input_postgre_sql_serverzone"></a> [postgre\_sql\_serverzone](#input\_postgre\_sql\_serverzone) | The availability zone for the PostgreSQL Flexible Server. | `string` | n/a | yes |
| <a name="input_postgresql_flexible_server_name"></a> [postgresql\_flexible\_server\_name](#input\_postgresql\_flexible\_server\_name) | The name of the PostgreSQL Flexible Server. | `string` | n/a | yes |
| <a name="input_postgresql_flexible_server_sku_name"></a> [postgresql\_flexible\_server\_sku\_name](#input\_postgresql\_flexible\_server\_sku\_name) | The SKU name for the PostgreSQL Flexible Server. | `string` | n/a | yes |
| <a name="input_postgresql_flexible_server_storage_size"></a> [postgresql\_flexible\_server\_storage\_size](#input\_postgresql\_flexible\_server\_storage\_size) | The storage size for the PostgreSQL Flexible Server in MB. | `number` | n/a | yes |
| <a name="input_postgresql_flexible_server_version"></a> [postgresql\_flexible\_server\_version](#input\_postgresql\_flexible\_server\_version) | The version of the PostgreSQL Flexible Server. | `string` | n/a | yes |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Enable or disable public network access for the PostgreSQL Flexible Server. | `bool` | `false` | no |
| <a name="input_resource_group_location"></a> [resource\_group\_location](#input\_resource\_group\_location) | The Azure region where the resource group will be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group where resources will be created. | `string` | n/a | yes |
| <a name="input_service_plan_os_type"></a> [service\_plan\_os\_type](#input\_service\_plan\_os\_type) | The OS type for the App Service Plan. | `string` | n/a | yes |
| <a name="input_service_plan_sku_name"></a> [service\_plan\_sku\_name](#input\_service\_plan\_sku\_name) | The SKU name for the App Service Plan. | `string` | n/a | yes |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | The name of the storage account. | `string` | n/a | yes |
| <a name="input_storage_blob_name"></a> [storage\_blob\_name](#input\_storage\_blob\_name) | The name of the storage blob to be created. | `string` | n/a | yes |
| <a name="input_storage_container_name"></a> [storage\_container\_name](#input\_storage\_container\_name) | The name of the storage container within the storage account. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_create_user_endpoint"></a> [create\_user\_endpoint](#output\_create\_user\_endpoint) | Complete endpoint URL for creating PostgreSQL users |
| <a name="output_created_users_summary"></a> [created\_users\_summary](#output\_created\_users\_summary) | Summary of created PostgreSQL users and their privileges |
| <a name="output_function_app_name"></a> [function\_app\_name](#output\_function\_app\_name) | Name of the Function App for user management |
| <a name="output_function_app_url"></a> [function\_app\_url](#output\_function\_app\_url) | Base URL of the Function App |
| <a name="output_get_function_key_command"></a> [get\_function\_key\_command](#output\_get\_function\_key\_command) | Azure CLI command to retrieve the function key for API access |
| <a name="output_key_vault_name"></a> [key\_vault\_name](#output\_key\_vault\_name) | Name of the Key Vault storing PostgreSQL user passwords |
| <a name="output_key_vault_uri"></a> [key\_vault\_uri](#output\_key\_vault\_uri) | URI of the Key Vault storing PostgreSQL user passwords |
| <a name="output_password_retrieval_commands"></a> [password\_retrieval\_commands](#output\_password\_retrieval\_commands) | Commands to retrieve PostgreSQL user passwords from Key Vault |
| <a name="output_postgresql_database_name"></a> [postgresql\_database\_name](#output\_postgresql\_database\_name) | Name of the PostgreSQL database |
| <a name="output_postgresql_server_fqdn"></a> [postgresql\_server\_fqdn](#output\_postgresql\_server\_fqdn) | FQDN of the PostgreSQL Flexible Server |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group |
| <a name="output_service_plan_name"></a> [service\_plan\_name](#output\_service\_plan\_name) | Name of the App Service Plan |
| <a name="output_service_plan_sku"></a> [service\_plan\_sku](#output\_service\_plan\_sku) | SKU of the App Service Plan |
| <a name="output_user_management_instructions"></a> [user\_management\_instructions](#output\_user\_management\_instructions) | Instructions for managing PostgreSQL users via Function API |
| <a name="output_user_management_with_keyvault_instructions"></a> [user\_management\_with\_keyvault\_instructions](#output\_user\_management\_with\_keyvault\_instructions) | Complete instructions for managing PostgreSQL users with Key Vault passwords - Pure Terraform |
