# Resource Group (create if absent)
resource "azurerm_resource_group" "rg_new" {
  name     = var.second_resource_group_name
  location = var.resource_group_location
  tags     = var.tags
}

# Distinct set of locations needed for Service Plans (one per location)
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

# ✅ ONE App Service Plan per environment/location
resource "azurerm_service_plan" "asp_env" {
  for_each = local.plans

  name                = "asp-${replace(each.key, " ", "-")}"
  resource_group_name = azurerm_resource_group.rg_new.name
  location            = each.value.location
  os_type             = "Linux"
  sku_name            = each.value.sku
  tags                = var.tags
}

# ✅ ONE Linux Web App per entry
resource "azurerm_linux_web_app" "app" {
  for_each = var.webapps

  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg_new.name
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

# ✅ Output: fixed default_hostname attribute
output "webapp_hostnames" {
  value = {
    for k, v in azurerm_linux_web_app.app : k => v.default_hostname
  }
}
