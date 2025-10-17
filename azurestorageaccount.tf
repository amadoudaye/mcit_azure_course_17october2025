resource "azurerm_storage_account" "azurestoagemcit" {
  name                     = "mcitoctostorage"
  resource_group_name      = azurerm_resource_group.rgoctobermcit.name
  location                 = azurerm_resource_group.rgoctobermcit.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}
