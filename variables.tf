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


