terraform {
    required_providers {
        azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 3.80"
        }
        
        # Archive provider for automatic function packaging
        archive = {
            source  = "hashicorp/archive"
            version = "~> 2.4"
        }

        random = {
            source  = "hashicorp/random"
            version = "~> 3.4"
        }
        
        # External provider for getting function keys via Azure CLI
        external = {
            source  = "hashicorp/external"
            version = "~> 2.3"
        }
        null = {
            source  = "hashicorp/null"
            version = "~> 3.2"
        }
    }
    
    required_version = ">=1.0"
}

provider "azurerm" {
    features {}
}