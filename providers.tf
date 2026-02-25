terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.50"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}
