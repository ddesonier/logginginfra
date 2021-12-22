provider "azurerm" {
  features {}
  subscription_id = "7c27312f-200e-47f6-a855-c308a26f1493"
  skip_provider_registration = "true"
}

resource "azurerm_resource_group" "value" {
  name     = "LoggingTest_Damon"
  location = "EastUS"
}


resource "azurerm_storage_account" "value" {
  name                     = "nomadtestlogana"
  resource_group_name      = azurerm_resource_group.value.name
  location                 = azurerm_resource_group.value.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "test"
  }
}