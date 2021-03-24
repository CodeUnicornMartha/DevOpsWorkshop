terraform {
  backend "azurerm" {
    resource_group_name  = "pwcterraformstate"
    storage_account_name = "pwcterraformstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

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

  location            = local.location
  resource_group_name = azurerm_resource_group.devops.name

  account_tier             = "Standard"
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
  location            = local.location

  storage_account_name       = azurerm_storage_account.upload.name
  storage_account_access_key = azurerm_storage_account.upload.primary_access_key


  app_service_plan_id = azurerm_app_service_plan.function.id
}

resource "azurerm_function_app" "cognitive_service" {
  name = "cognitiveservicefunction"

  resource_group_name = azurerm_resource_group.devops.name
  location            = local.location

  storage_account_name       = azurerm_storage_account.upload.name
  storage_account_access_key = azurerm_storage_account.upload.primary_access_key


  app_service_plan_id = azurerm_app_service_plan.function.id
}

resource "azurerm_cosmosdb_account" "cosmos_db" {
  name                = "devops-cosmos-db-masplitt"
  location            = azurerm_resource_group.devops.location
  resource_group_name = azurerm_resource_group.devops.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "EnableMongo"
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

resource "azurerm_cosmosdb_mongo_collection" "collection" {
  name                = "tfex-cosmos-mongo-db"
  resource_group_name = azurerm_cosmosdb_account.cosmos_db.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos_db.name
  database_name       = azurerm_cosmosdb_mongo_database.mongo.name

  index {
    keys = [
      "_id",
    ]
    unique = true
  }

  default_ttl_seconds = "777"
  shard_key           = "uniqueKey"
  throughput          = 400
}

resource "azurerm_application_insights" "appinsights" {
  name                = "workspace-devops-ai"
  location            = azurerm_resource_group.devops.location
  resource_group_name = azurerm_resource_group.devops.name
  application_type    = "web"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault" {
  name                = "kv-cw-ms"
  location            = azurerm_resource_group.devops.location
  resource_group_name = azurerm_resource_group.devops.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
  purge_protection_enabled = true
}


resource "azurerm_machine_learning_workspace" "aiworkspace" {
  name                    = "ai-workspace"
  location                = azurerm_resource_group.devops.location
  resource_group_name     = azurerm_resource_group.devops.name
  application_insights_id = azurerm_application_insights.appinsights.id
  key_vault_id            = azurerm_key_vault.keyvault.id
  storage_account_id      = azurerm_storage_account.upload.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_account" "formrecognizer" {
  name                = "formrecognizer-account"
  location            = azurerm_resource_group.devops.location
  resource_group_name = azurerm_resource_group.devops.name
  kind                = "FormRecognizer"

  sku_name = "S0"

  tags = {
    Acceptance = "Test"
  }
}

resource "azurerm_powerbi_embedded" "powerbi" {
  name                = "devopsclwaltke"
  location            = azurerm_resource_group.devops.location
  resource_group_name = azurerm_resource_group.devops.name
  sku_name            = "A1"
  administrators      = ["clwaltke@microsoft.com"]
}