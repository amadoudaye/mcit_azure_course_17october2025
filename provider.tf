terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"   # 👈 forces Terraform Cloud to use the latest v4.x provider
    }
  }
}

provider "azurerm" {
  features {}
}
