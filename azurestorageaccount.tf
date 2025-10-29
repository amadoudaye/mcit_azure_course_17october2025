resource "azurerm_storage_account" "azurestoagemcit" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rgoctobermcit.name
  location                 = azurerm_resource_group.rgoctobermcit.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  tags = {
    environment = var.environment
  }
}
