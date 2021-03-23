provider "azurerm" {
  features {}
}

locals {
  location = "westeurope"
}

resource "azurerm_resource_group" "devops" {
  name     = "devops_workshop"
  location = local.location
}

resource "azurerm_storage_account" "upload" {
  name = "uploadstoragefornewdocs"

  location = local.location
  resource_group_name = azurerm_resource_group.devops.name

  account_tier = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "function" {
  name                = "function-appservice-plan"
  location            = azurerm_resource_group.devops.location
  resource_group_name = azurerm_resource_group.devops.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_function_app" "upload" {
  name = "uploadstoragefornewdocs"

  resource_group_name = azurerm_resource_group.devops.name
  location = local.location
    
  storage_account_name = azurerm_storage_account.upload.name
  storage_account_access_key = azurerm_storage_account.upload.primary_access_key


  app_service_plan_id = azurerm_app_service_plan.function.id
}

resource "azurerm_function_app" "cognitive_service" {
  name = "cognitiveservicefunction"

  resource_group_name = azurerm_resource_group.devops.name
  location = local.location
    
  storage_account_name = azurerm_storage_account.upload.name
  storage_account_access_key = azurerm_storage_account.upload.primary_access_key


  app_service_plan_id = azurerm_app_service_plan.function.id
}

resource "azurerm_cosmosdb_account" "cosmos_db" {
  name                = "devops-cosmos-db"
  location            = azurerm_resource_group.devops.location
  resource_group_name = azurerm_resource_group.devops.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = azurerm_resource_group.devops.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_mongo_database" "mongo" {
  name                = "tfex-cosmos-mongo-db"
  resource_group_name = azurerm_cosmosdb_account.cosmos_db.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos_db.name
  throughput          = 400
}