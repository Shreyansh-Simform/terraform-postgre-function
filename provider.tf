terraform {
    required_providers {
        azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 3.80"
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
        
        # HTTP provider for getting current IP address
        http = {
            source  = "hashicorp/http"
            version = "~> 3.4"
        }
        
        # Time provider for wait delays
        time = {
            source  = "hashicorp/time"
            version = "~> 0.9"
        }
    }
    
    required_version = ">=1.0"
}

provider "azurerm" {
    features {}
}