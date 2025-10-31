terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.70.0"   # 👈 This version is for azurem, not terraform version
    }
  }
required_version=">=1.4.0" #this version is for terraform version, not azurem
}

provider "azurerm" {
  features {}
subscription_id=var.subscription_id
client_id=var.client_id
client_secret=var.client_secret
tenant_id=var.tenant_id
}
