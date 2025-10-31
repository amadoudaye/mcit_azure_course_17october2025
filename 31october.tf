# Resource Group (create if absent)
resource "azurerm_resource_group" "rg_new" {
  name     = var.second_resource_group_name
  location = var.resource_group_location
  tags     = var.tags
}
 
# Distinct set of locations needed for Service Plans (one per location)
locals {
  locations = toset([for w in var.webapps : w.location])
}
 
# App Service Plan per location (Linux)
resource "azurerm_service_plan" "asp" {
  for_each = local.locations
 
  name                = "asp-${each.value}"
  resource_group_name = azurerm_resource_group.rg_new.name
  location            = each.value
  os_type             = "Linux"
  sku_name            = "B1" # temporary; overridden below via lifecycle block or use a shared default
  tags                = var.tags
}
 
# Because each app might want a different SKU by env,
# we set plan SKUs using per-app lookup by env.
# A simple approach: one plan per LOCATION **and** ENV (so SKU can differ).
locals {
  plans = {
    for k, v in var.webapps :
    "${v.location}-${v.env}" => {
      location = v.location
      env      = v.env
      sku      = lookup(var.sku_by_env, v.env, "P1v3") # <--- lookup() with default
    }
  }
}
 
# Recreate service plans keyed by location-env (overrides earlier single-per-location approach)
# If you prefer ONE plan per location, comment this block and use the first asp.
resource "azurerm_service_plan" "asp_env" {
  for_each = local.plans
 
  name                = "asp-${replace(each.key, " ", "")}"
  resource_group_name = azurerm_resource_group.rg_new.name
  location            = each.value.location
  os_type             = "Linux"
  sku_name            = each.value.sku # <--- comes from lookup(var.sku_by_env,...)
  tags                = var.tags
}
 
# Linux Web Apps – for_each over the webapps map
resource "azurerm_linux_web_app" "app" {
  for_each = var.webapps
 
  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg_new.name
  location            = each.value.location
 
 
  # Bind to the plan matched by location-env
  service_plan_id = azurerm_service_plan.asp_env["${each.value.location}-${each.value.env}"].id
 
  https_only = true
  tags       = merge(var.tags, { env = each.value.env })
     site_config {}
 
 
  # Demonstrating lookup() for an optional app setting with a default:
  # If FEATURE_FLAG not provided per app, default to "off".
  app_settings = merge(
    {
      "WEBSITE_RUN_FROM_PACKAGE" = "0"
      "FEATURE_FLAG"             = lookup(each.value.app_settings, "FEATURE_FLAG", "off") # <--- lookup()
    },
    each.value.app_settings
  )
 
  identity {
    type = "SystemAssigned"
  }
}
