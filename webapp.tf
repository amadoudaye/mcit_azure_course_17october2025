variable "resource_group_name" {
 description = "Name of the RG to create/use"
 type        = string
}
variable "resource_group_location" {
 description = "Location for the RG (used if it doesn't exist)"
 type        = string
}
# Map of web apps to create. Keys must be unique IDs you choose.
# Each item: name, location, env, runtime, and optional app_settings map.
variable "webapps" {
 description = "Map of Linux Web Apps to deploy"
 type = map(object({
   name         : string
   location     : string
   env          : string          # e.g., dev/qa/prod
   runtime      : string          # e.g., "PYTHON|3.11", "NODE|18-lts"
   app_settings : map(string)     # optional settings per app (can be {})
 }))
}
# Example: pick SKU by environment with lookup(); defaults to P1v3 if env missing.
variable "sku_by_env" {
 description = "Map from env to App Service Plan SKU"
 type        = map(string)
 default = {
   dev  = "B1"
   qa   = "S1"
   prod = "P1v3"
 }
}
variable "tags" {
 description = "Common tags"
 type        = map(string)
 default     = {}
}
# Resource Group (create if absent)
resource "azurerm_resource_group" "rg" {
 name     = var.resource_group_name
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
 resource_group_name = azurerm_resource_group.rg.name
 location            = each.value
 os_type  = "Linux"
 sku_name = "B1" # temporary; overridden below via lifecycle block or use a shared default
 tags     = var.tags
}
# Because each app might want a different SKU by env,
# we set plan SKUs using per-app lookup by env.
# A simple approach: one plan per LOCATION **and** ENV (so SKU can differ).
# If you want one plan per location only, skip this block and keep one SKU.
# ---- Alternate: plan key is location+env so each env can have its own SKU
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
 resource_group_name = azurerm_resource_group.rg.name
 location            = each.value.location
 os_type  = "Linux"
 sku_name = each.value.sku # <--- comes from lookup(var.sku_by_env,...)
 tags     = var.tags
}
# Linux Web Apps – for_each over the webapps map
resource "azurerm_linux_web_app" "app" {
 for_each = var.webapps
 name                = each.value.name
 resource_group_name = azurerm_resource_group.rg.name
 location            = each.value.location
 # Bind to the plan matched by location-env
 service_plan_id = azurerm_service_plan.asp_env["${each.value.location}-${each.value.env}"].id
 https_only = true
 tags       = merge(var.tags, { env = each.value.env })
 site_config {
   linux_fx_version = each.value.runtime  # e.g., "PYTHON|3.11"
   ftps_state       = "Disabled"
 }
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
output "webapp_hostnames" {
 value = {
   for k, v in azurerm_linux_web_app.app : k => v.default_host_name
 }
}
