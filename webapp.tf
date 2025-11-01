variable "resource_group_name" {
  description = "Name of the RG to create/use"
  type        = string
}

variable "resource_group_location" {
  description = "Location for the RG (used if it doesn't exist)"
  type        = string
}

variable "webapps" {
  description = "Map of Linux Web Apps to deploy"
  type = map(object({
    name         : string
    location     : string
    env          : string
    runtime      : string
    app_settings : map(string)
  }))
}

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

# ---------------------------
# Resource Group
# ---------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags     = var.tags
}

# ---------------------------
# Distinct locations
# ---------------------------
locals {
  locations = toset([for w in var.webapps : w.location])
}

# ---------------------------
# Service plan per location
# ---------------------------
resource "azurerm_service_plan" "asp" {
  for_each = local.locations

  name                = "asp-${replace(each.value, " ", "-")}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = each.value
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = var.tags
}

# ---------------------------
# Plans keyed by location-env
# ---------------------------
locals {
  plans = {
    for k, v in var.webapps :
    "${v.location}-${v.env}" => {
      location = v.location
      env      = v.env
      sku      = lookup(var.sku_by_env, v.env, "P1v3")
    }
  }
}

# ---------------------------
# Service plan per environment
# ---------------------------
resource "azurerm_service_plan" "asp_env" {
  for_each = local.plans

  name                = "asp-${replace(each.key, " ", "-")}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = each.value.location
  os_type             = "Linux"
  sku_name            = each.value.sku
  tags                = var.tags
}

# ---------------------------
# Web apps
# ---------------------------
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

# ---------------------------
# Outputs
# ---------------------------
output "webapp_hostnames" {
  value = {
    for k, v in azurerm_linux_web_app.app : k => v.default_hostname
  }
}
