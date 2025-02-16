terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~>4.0"
        }
    }
}

data "azurerm_resource_group" "databricks" {
    name = var.resource_group_name
}

module "avm-res-databricks-workspace" {
  source  = "Azure/avm-res-databricks-workspace/azurerm"
  version = "0.2.0"
  
  resource_group_name   = data.azurerm_resource_group.databricks.name
  location              = data.azurerm_resource_group.databricks.location
  name                  = var.workspace_name
  sku                   = "premium"
}
