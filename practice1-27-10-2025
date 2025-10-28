# -----------------------------
# Resource Group
# -----------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# -----------------------------
# Variables
# -----------------------------
variable "rg_name" {
  description = "The name of the Azure Resource Group"
  type        = string
  default     = "my-resource-group"
}

variable "location" {
  description = "The Azure region for the Resource Group"
  type        = string
  default     = "East US"
}

variable "project" {
  description = "The project name used in naming resources"
  type        = string
  default     = "myapp"
}

variable "plan_sku_linux" {
  description = "SKU for Linux App Service Plan"
  type        = string
  default     = "B1"
}

variable "plan_sku_windows" {
  description = "SKU for Windows App Service Plan"
  type        = string
  default     = "B1"
}

variable "linux_node_version" {
  description = "Node version for Linux app"
  type        = string
  default     = "18-lts"
}

variable "windows_dotnet_version" {
  description = "Dotnet version for Windows app"
  type        = string
  default     = "v6.0"
}

variable "linux_app_name" {
  description = "Base name for Linux web app"
  type        = string
  default     = "linuxwebapp"
}

variable "windows_app_name" {
  description = "Base name for Windows web app"
  type        = string
  default     = "windowswebapp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "common_app_settings" {
  description = "Common application settings"
  type        = map(string)
  default     = {}
}

variable "linux_app_settings" {
  description = "Linux-specific app settings"
  type        = map(string)
  default     = {}
}

variable "windows_app_settings" {
  description = "Windows-specific app settings"
  type        = map(string)
  default     = {}
}

# -----------------------------
# Random suffix (for uniqueness)
# -----------------------------
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# -----------------------------
# App Service Plans
# -----------------------------
resource "azurerm_service_plan" "plan_linux" {
  name                = "${var.project}-linux-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = var.plan_sku_linux
}

resource "azurerm_service_plan" "plan_windows" {
  name                = "${var.project}-windows-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = var.plan_sku_windows
}

# -----------------------------
# Application Insights
# -----------------------------
resource "azurerm_application_insights" "ai_linux" {
  name                = "${var.project}-ai-linux-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_application_insights" "ai_windows" {
  name                = "${var.project}-ai-windows-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

# -----------------------------
# Linux Web App
# -----------------------------
resource "azurerm_linux_web_app" "app_linux" {
  name                = "${var.linux_app_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan_linux.id
  https_only          = true

  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"

    application_stack {
      node_version = var.linux_node_version
    }
  }

  app_settings = merge(
    var.common_app_settings,
    {
      "WEBSITE_RUN_FROM_PACKAGE"             = "0"
      "WEBSITES_ENABLE_APP_SERVICE_STORAGE"  = "false"
      "APPINSIGHTS_INSTRUMENTATIONKEY"       = azurerm_application_insights.ai_linux.instrumentation_key
      "APPLICATIONINSIGHTS_CONNECTION_STRING"= azurerm_application_insights.ai_linux.connection_string
      "ASPNETCORE_ENVIRONMENT"               = var.environment
    },
    var.linux_app_settings
  )

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"]
    ]
  }
}

# -----------------------------
# Windows Web App
# -----------------------------
resource "azurerm_windows_web_app" "app_windows" {
  name                = "${var.windows_app_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan_windows.id
  https_only          = true

  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"

    application_stack {
      current_stack  = "dotnet"
      dotnet_version = var.windows_dotnet_version
    }
  }

  app_settings = merge(
    var.common_app_settings,
    {
      "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.ai_windows.instrumentation_key
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.ai_windows.connection_string
      "WEBSITE_HTTPLOGGING_RETENTION_DAYS"    = "7"
      "ASPNETCORE_ENVIRONMENT"                = var.environment
    },
    var.windows_app_settings
  )

  identity {
    type = "SystemAssigned"
  }
}

# -----------------------------
# Outputs
# -----------------------------
output "linux_web_app_name" {
  value = azurerm_linux_web_app.app_linux.name
}

output "linux_web_app_url" {
  value = "https://${azurerm_linux_web_app.app_linux.default_hostname}"
}

output "windows_web_app_name" {
  value = azurerm_windows_web_app.app_windows.name
}

output "windows_web_app_url" {
  value = "https://${azurerm_windows_web_app.app_windows.default_hostname}"
}
