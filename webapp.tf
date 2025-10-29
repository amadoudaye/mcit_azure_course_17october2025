terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
}

# ------------------------------------------------------
# Variables
# ------------------------------------------------------
variable "resource_group_name" {
  description = "Name of the RG to create/use"
  type        = string
  default     = "rg-webapps"
}

variable "resource_group_location" {
  description = "Location for the RG (used if it doesn't exist)"
  type        = string
  default     = "Canada Central"
}

variable "webapps" {
  description = "Map of Linux Web Apps to deploy"
  type = map(object({
    name         = string
    location     = string
    env          = string          # e.g., dev/qa/prod
    runtime      = string          # e.g., PYTHON|3.11 or NODE|18-lts
    app_settings = optional(map(string), {})  # optional settings per app
  }))

  default = {
    app1 = {
      name         = "my-python-app"
      location     = "Canada Central"
      env          = "dev"
      runtime      = "PYTHON|3.11"
      app_settings = {
        "FEATURE_FLAG" = "on"
      }
    }

    app2 = {
      name         = "my-node-app"
      location     = "Canada Central"
      env          = "qa"
      runtime      = "NODE|18-lts"
      app_settings = {}
    }
  }
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
  default = {
    project = "WebAppsDemo"
    owner   = "Amadou"
  }
}

# ------------------------------------------------------
# Resource Group
# ------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags     = var.tags
}

# ------------------------------------------------------
# Locals
# ------------------------------------------------------
locals {
  # All distinct locations from webapps
  locations = toset([for w in var.webapps : w.location])

  # Plans per location-env (so each env can have its own SKU)
  plans = {
    for k, v in var.webapps :
    "${v.location}-${v.env}" => {
      location = v.location
      env      = v.env
      sku      = lookup(var.sku_by_env, v.env, "P1v3")
    }
  }
}

# ------------------------------------------------------
# App Service Plan per location-env
# ------------------------------------------------------
resource "azurerm_service_plan" "asp_env" {
  for_each = local.plans

  name                = "asp-${replace(each.key, " ", "")}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = each.value.location
  os_type             = "Linux"
  sku_name            = each.value.sku
  tags                = var.tags
}

# ------------------------------------------------------
# Linux Web Apps
# ------------------------------------------------------
resource "azurerm_linux_web_app" "app" {
  for_each = var.webapps

  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = each.value.location
  service_plan_id     = azurerm_service_plan.asp_env["${each.value.location}-${each.value.env}"].id
  https_only          = true
  tags                = merge(var.tags, { env = each.value.env })

  site_config {
    linux_fx_version = each.value.runtime
    ftps_state       = "Disabled"
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

# ------------------------------------------------------
# Outputs
# ------------------------------------------------------
output "webapp_hostnames" {
  description = "Default hostnames for the deployed Web Apps"
  value = {
    for k, v in azurerm_linux_web_app.app : k => v.default_host_name
  }
}
