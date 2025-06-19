#General Variables
//Business Unit 
variable "business_unit" {
  description = "The business unit for which the resources are being created."
  type        = string
}

//Environment
variable "environment" {
  description = "The environment for which the resources are being created (e.g., dev, test, prod)."
  type        = string
}

#Resource Group Variable
//Resource Group Name 
variable "resource_group_name" {
  description = "The name of the resource group where resources will be created."
  type        = string
}

//Resource Group Location
variable "resource_group_location" {
  description = "The Azure region where the resource group will be created."
  type        = string
}

#Virtual Network Variables
/*
//Virtual Network Name
variable "virtual_network_name" {
  description = "The name of the virtual network."
  type        = string
}

//Virtual Network Address Space
variable "virtual_network_address_space" {
  description = "The address space for the virtual network in CIDR notation."
  type        = list(string)
}

//Subnet Name
variable "subnet_name" {
  description = "The name of the subnet within the virtual network."
  type        = string
}
*/

#PostgreSQL Variables

//PostgreSQL Flexible Server Name
variable "postgresql_flexible_server_name" {
  description = "The name of the PostgreSQL Flexible Server."
  type        = string
}

//PostgreSQL Flexible Server Version
variable "postgresql_flexible_server_version" {
  description = "The version of the PostgreSQL Flexible Server."
  type        = string
}

//Public Network Access Enabled
variable "public_network_access_enabled" {
  description = "Enable or disable public network access for the PostgreSQL Flexible Server."
  type        = bool
  default     = false
}

// PostgreSQL Flexible Server Administrator Login
variable "postgre_admin_login" {
  description = "The administrator login for the PostgreSQL Flexible Server."
  type        = string
  sensitive   = true
}

// PostgreSQL Flexible Server Administrator Password
variable "postgre_admin_password" {
  description = "The administrator password for the PostgreSQL Flexible Server."
  type        = string
  sensitive   = true
}

//  PostgreSQL Flexible Server Zone
variable "postgre_sql_serverzone" {
  description = "The availability zone for the PostgreSQL Flexible Server."
  type        = string
}

// PostgreSQL Flexible Server Storage Size
variable "postgresql_flexible_server_storage_size" {
  description = "The storage size for the PostgreSQL Flexible Server in MB."
  type        = number
}

// PostgreSQL Flexible Server SKU Name
variable "postgresql_flexible_server_sku_name" {
  description = "The SKU name for the PostgreSQL Flexible Server."
  type        = string
}

// PostgreSQL Database Name
variable "database_name" {
  description = "The name of the PostgreSQL database to be created."
  type        = string
}

#Storage Variables

//Storage Account Name
variable "storage_account_name" {
  description = "The name of the storage account."
  type        = string
}

//Storage Account Performance Tier
variable "account_tier" {
  description = "The performance tier of the storage account."
  type        = string
  default     = "Standard"
}

//  Storage Account Replication Type
variable "account_replication_type" {
  description = "The replication type of the storage account."
  type        = string
  default     = "LRS"
}

//  Storage Container Name
variable "storage_container_name" {
  description = "The name of the storage container within the storage account."
  type        = string  
}

//  Storage Blob Name
variable "storage_blob_name" {
  description = "The name of the storage blob to be created."
  type        = string
}

#Function App Variables

// App Service Plan Variables
variable "app_service_plan_name" {
  description = "The name of the App Service Plan."
  type        = string
}

// Function App Variables
variable "function_app_name" {
  description = "The name of the Function App."
  type        = string
}

//Service Plan OS Type
variable "service_plan_os_type" {
  description = "The OS type for the App Service Plan."
  type        = string
}

// Service Plan SKU Name
variable "service_plan_sku_name" {
  description = "The SKU name for the App Service Plan."
  type        = string
}