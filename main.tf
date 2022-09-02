

data "azurerm_client_config" "current" {}


locals {
  acs_domain_name = var.use_prefix ? join("", [lower(var.domain_prefix), lower(var.acs_domain_name), "-", lower(random_id.acs_unique_id.hex)]) : lower(var.acs_domain_name)
  inside_vpc      = length(var.vpc_options["subnet_ids"]) > 0 ? true : false
}

data "azuread_user" "user" {
  user_principal_name = var.user_principal_name
}

resource "azurerm_resource_group" "acs_rg" {
  count    = "N" == var.acs_rg_YN ? 1 : 0
  name     = "" == var.acs_rg_name ? "nasuni-labs-acs-rg" : var.acs_rg_name
  location = var.azure_location
}

resource "azurerm_search_service" "acs" {
  name                = local.acs_domain_name
  resource_group_name = "N" == var.acs_rg_YN ? azurerm_resource_group.acs_rg[0].name : var.acs_rg_name
  location            = "N" == var.acs_rg_YN ? azurerm_resource_group.acs_rg[0].location : var.azure_location
  sku                 = "standard"

  tags = merge(
    {
      "Domain" = lower(local.acs_domain_name)
    },
    var.tags,
  )
  depends_on = [
    azurerm_resource_group.acs_rg
  ]
}

resource "random_id" "acs_unique_id" {
  byte_length = 3
}

resource "azurerm_app_configuration" "appconf" {
  name                = var.acs_admin_app_config_name
  resource_group_name = "N" == var.acs_rg_YN ? azurerm_resource_group.acs_rg[0].name : var.acs_rg_name
  location            = "N" == var.acs_rg_YN ? azurerm_resource_group.acs_rg[0].location : var.azure_location
  depends_on = [
    azurerm_search_service.acs
  ]
}

resource "azurerm_role_assignment" "appconf_dataowner" {
  scope                = azurerm_app_configuration.appconf.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azuread_user.user.object_id
}


resource "azurerm_app_configuration_key" "destination_container_name" {
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = "destination-container-name"
  label                  = "destination-container-name"
  value                  = var.destination_container_name

  depends_on = [
    azurerm_role_assignment.appconf_dataowner
  ]
}

resource "azurerm_app_configuration_key" "datasource_connection_string" {
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = "datasource-connection-string"
  label                  = "datasource-connection-string"
  value                  = var.datasource_connection_string

  depends_on = [
    azurerm_role_assignment.appconf_dataowner
  ]
}

resource "azurerm_app_configuration_key" "acs_resource_group" {
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = "acs-resource-group"
  label                  = "acs-resource-group"
  value                  = azurerm_search_service.acs.resource_group_name

  depends_on = [
    azurerm_role_assignment.appconf_dataowner
  ]
}

resource "azurerm_app_configuration_key" "acs_service_name" {
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = "acs-service-name"
  label                  = "acs-service-name"
  value                  = azurerm_search_service.acs.name

  depends_on = [
    azurerm_role_assignment.appconf_dataowner
  ]
}

resource "azurerm_app_configuration_key" "acs_api_key" {
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = "acs-api-key"
  label                  = "acs-api-key"
  value                  = azurerm_search_service.acs.primary_key

  depends_on = [
    azurerm_role_assignment.appconf_dataowner
  ]
}

resource "azurerm_app_configuration_key" "nmc_api_acs_url" {
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = "nmc-api-acs-url"
  label                  = "nmc-api-acs-url"
  value                  = "https://${azurerm_search_service.acs.name}.search.windows.net"

  depends_on = [
    azurerm_role_assignment.appconf_dataowner
  ]
}

output "appconf_dataowner_principal_id" {
  value = azurerm_role_assignment.appconf_dataowner.principal_id
}