# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.2"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      purge_soft_deleted_secrets_on_destroy = false
    }
  }
  
  # use_msi = true
  # subscription_id = var.subscription_id
  # tenant_id       = var.tenant_id
}
