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
  name                = "asp-${replace(each.value, " ", "-")}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = each.value
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = var.tags
}
resource "azurerm_linux_web_app" "app" {
  for_each = var.webapps

  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = each.value.location
  service_plan_id     = azurerm_service_plan.asp_env["${each.value.location}-${each.value.env}"].id
  https_only          = true
  tags                = merge(var.tags, { env = each.value.env })

  site_config {
    ftps_state = "Disabled"

    dynamic "application_stack" {
      for_each = [each.value.runtime]
      content {
        python_version = contains(each.value.runtime, "PYTHON") ? split("|", each.value.runtime)[1] : null
        node_version   = contains(each.value.runtime, "NODE") ? split("|", each.value.runtime)[1] : null
      }
    }
  }

  app_settings = merge(
    {
      "WEBSITE_RUN_FROM_PACKAGE" = "0"
      "FEATURE_FLAG"             = lookup(each.value.app_settings, "FEATURE_FLAG", "off")
    },
    each.value.app_settings
  )

  identity {
    type = "SystemAssigned"
  }
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
