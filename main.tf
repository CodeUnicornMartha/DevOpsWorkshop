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