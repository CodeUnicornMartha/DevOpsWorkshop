provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "devops" {
  name     = "devops_workshop"
  location = "westeurope"
}
