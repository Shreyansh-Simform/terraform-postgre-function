## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.80 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.4 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.117.1 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.5.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.user_passwords](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_secret.user_passwords](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.users_summary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_postgresql_flexible_server.my-server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_database.my-postgre-db](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.azure_services](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.terraform_client](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_resource_group.myrg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.terraform_kv_secrets_officer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [null_resource.create_postgresql_users](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.user_passwords](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [time_sleep.wait_for_db](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_rbac_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [http_http.my_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | The business unit for which the resources are being created. | `string` | n/a | yes |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | The name of the PostgreSQL database to be created. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment for which the resources are being created (e.g., dev, test, prod). | `string` | n/a | yes |
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

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connection_info"></a> [connection\_info](#output\_connection\_info) | Database connection information for applications |
| <a name="output_created_users_summary"></a> [created\_users\_summary](#output\_created\_users\_summary) | Summary of created PostgreSQL users and their privileges |
| <a name="output_key_vault_auth_model"></a> [key\_vault\_auth\_model](#output\_key\_vault\_auth\_model) | Authentication model used by Key Vault |
| <a name="output_key_vault_name"></a> [key\_vault\_name](#output\_key\_vault\_name) | Name of the Key Vault storing PostgreSQL user passwords |
| <a name="output_key_vault_uri"></a> [key\_vault\_uri](#output\_key\_vault\_uri) | URI of the Key Vault storing PostgreSQL user passwords |
| <a name="output_password_retrieval_commands"></a> [password\_retrieval\_commands](#output\_password\_retrieval\_commands) | Commands to retrieve PostgreSQL user passwords from Key Vault |
| <a name="output_postgresql_database_name"></a> [postgresql\_database\_name](#output\_postgresql\_database\_name) | Name of the PostgreSQL database |
| <a name="output_postgresql_server_fqdn"></a> [postgresql\_server\_fqdn](#output\_postgresql\_server\_fqdn) | FQDN of the PostgreSQL Flexible Server |
| <a name="output_postgresql_server_version"></a> [postgresql\_server\_version](#output\_postgresql\_server\_version) | Version of the PostgreSQL Flexible Server |
| <a name="output_rbac_assignments"></a> [rbac\_assignments](#output\_rbac\_assignments) | RBAC role assignments for Key Vault access |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group |
| <a name="output_terraform_client_ip"></a> [terraform\_client\_ip](#output\_terraform\_client\_ip) | Current IP address that has access to PostgreSQL |
| <a name="output_user_management_info"></a> [user\_management\_info](#output\_user\_management\_info) | PostgreSQL user management information |
| <a name="output_user_management_instructions"></a> [user\_management\_instructions](#output\_user\_management\_instructions) | Complete instructions for managing PostgreSQL users with direct Terraform approach |
