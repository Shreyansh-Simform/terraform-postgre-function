# PostgreSQL Users Configuration File
# This file contains all user definitions and their configurations
# Modify this file to add, remove, or update users

locals {
  postgresql_users = {
    "shreyansh_user" = {
      privileges = "readwrite" 
      description = "Shreyansh user addition"
    }
    "vikram_patel" = {
      privileges = "full"
      description = "Vikram Patel user addition"
    }
    "nandini_vyas" = {
      privileges = "full"
      description = "Nandini Vyas user addition"
    }
    "bhavin_zala" = {
      privileges = "readonly"
      description = "Bhavin Zala user addition"
    }
  }
}