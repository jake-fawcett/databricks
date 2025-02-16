terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~>1.65.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "databricks-uks"
    storage_account_name = "sadatabricksukstf"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
    features {}
    subscription_id = "e9ec8865-e1f9-4db7-bcd5-028c913441e5"
}

module "databricks-workspace" {
  source = "./modules/databricks-workspace"
  resource_group_name = var.resource_group_name
  workspace_name = var.workspace_name
}

provider "databricks" {
    host = module.databricks-workspace.workspace_url
}

module "databricks-storage" {
  source = "./modules/databricks-storage"
  resource_group_name = var.resource_group_name
}