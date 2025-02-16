terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
    databricks = {
      source = "databricks/databricks"
      version = "~>1.65.0"
    }
  }
}

data "azurerm_resource_group" "databricks" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "databricks-data" {
  name                     = "sauksdatabricksdata"
  resource_group_name      = data.azurerm_resource_group.databricks.name
  location                 = data.azurerm_resource_group.databricks.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_container" "databricks-data-jf" {
  name                  = "scuksdatabricksdatajf"
  storage_account_id    = azurerm_storage_account.databricks-data.id
  container_access_type = "private"
}

resource "azurerm_databricks_access_connector" "databricks-data-jf" {
  name                = "das-uks-databricks-data-jf"
  resource_group_name = data.azurerm_resource_group.databricks.name
  location            = data.azurerm_resource_group.databricks.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "dac-uks-databricks-data-jf-storage-account-role" {
  scope                = azurerm_storage_account.databricks-data.id
  role_definition_name = "Storage Blob Delegator"
  principal_id         = azurerm_databricks_access_connector.databricks-data-jf.identity[0].principal_id
}

resource "azurerm_role_assignment" "dac-uks-databricks-data-jf-storage-container-role" {
  scope                = azurerm_storage_container.databricks-data-jf.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.databricks-data-jf.identity[0].principal_id
}

# TODO: Private Endpoint
# TODO: NCC

# TODO: Isolation Mode
resource "databricks_storage_credential" "databricks-data-jf" {
  name    = "sc-uks-jf"
  comment = "Managed identity credential managed by TF"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.databricks-data-jf.id
  }
}

resource "databricks_external_location" "databricks-data" {
  name            = "el-uks-jf"
  url             = "abfss://${azurerm_storage_container.databricks-data-jf.name}@${azurerm_storage_account.databricks-data.name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.databricks-data-jf.id
  comment         = "Managed by TF"
  skip_validation = true # This is due to an issue where Databricks falsely claims HNS is not enabled
  depends_on = [
    azurerm_role_assignment.dac-uks-databricks-data-jf-storage-account-role,
    azurerm_role_assignment.dac-uks-databricks-data-jf-storage-container-role
  ]
}

resource "databricks_catalog" "jf" {
  name    = "jf"
  comment = "this catalog is managed by terraform"
  storage_root = "abfss://${azurerm_storage_container.databricks-data-jf.name}@${azurerm_storage_account.databricks-data.name}.dfs.core.windows.net/"
}

resource "databricks_schema" "jf" {
  catalog_name = databricks_catalog.jf.id
  name         = "jf"
  comment      = "this database is managed by terraform"
}
