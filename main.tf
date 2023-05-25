data "azurerm_client_config" "current" {}

locals {
  acs_domain_name = var.use_prefix ? join("", [lower(var.domain_prefix), lower(var.acs_domain_name), "-", lower(random_id.acs_unique_id.hex)]) : lower(var.acs_domain_name)
  inside_vpc      = length(var.vpc_options["subnet_ids"]) > 0 ? true : false
}

data "azuread_service_principal" "user" {
  application_id = var.sp_application_id
}

data "azurerm_virtual_network" "VnetToBeUsed" {
  count               = var.use_private_acs == "Y" ? 1 : 0
  name                = var.user_vnet_name
  resource_group_name = var.networking_resource_group
}

data "azurerm_subnet" "azure_subnet_name" {
  count                = var.use_private_acs == "Y" ? 1 : 0
  name                 = var.user_subnet_name
  virtual_network_name = data.azurerm_virtual_network.VnetToBeUsed[0].name
  resource_group_name  = data.azurerm_virtual_network.VnetToBeUsed[0].resource_group_name
}

resource "azurerm_resource_group" "acs_rg" {
  count    = "N" == var.acs_rg_YN ? 1 : 0
  name     = "" == var.acs_rg_name ? "nasuni-labs-acs-rg" : var.acs_rg_name
  location = var.azure_location
}

############ INFO ::: Provisioning of Azure Cognitive Search :: Started ###############

data "azurerm_private_dns_zone" "acs_dns_zone" {
  count               = var.use_private_acs == "Y" ? 1 : 0
  name                = "privatelink.search.windows.net"
  resource_group_name = data.azurerm_virtual_network.VnetToBeUsed[0].resource_group_name
}

resource "azurerm_search_service" "acs" {
  name                          = local.acs_domain_name
  resource_group_name           = "N" == var.acs_rg_YN ? azurerm_resource_group.acs_rg[0].name : var.acs_rg_name
  location                      = "N" == var.acs_rg_YN ? azurerm_resource_group.acs_rg[0].location : var.azure_location
  sku                           = "standard2"
  public_network_access_enabled = var.use_private_acs == "Y" ? false : true
  tags = merge(
    {
      "Domain" = lower(local.acs_domain_name)
    },
    var.tags,
  )
  depends_on = [
    azurerm_resource_group.acs_rg,
    data.azurerm_private_dns_zone.acs_dns_zone
  ]
}

resource "azurerm_private_endpoint" "acs_private_endpoint" {
  count               = var.use_private_acs == "Y" ? 1 : 0
  name                = "${azurerm_search_service.acs.name}_private_endpoint"
  location            = data.azurerm_virtual_network.VnetToBeUsed[0].location
  resource_group_name = data.azurerm_virtual_network.VnetToBeUsed[0].resource_group_name
  subnet_id           = data.azurerm_subnet.azure_subnet_name[0].id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.acs_dns_zone[0].id]
  }

  private_service_connection {
    name                           = "${azurerm_search_service.acs.name}_connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_search_service.acs.id
    subresource_names              = ["searchService"]
  }

  provisioner "local-exec" {
    command = "az resource wait --updated --ids ${self.subnet_id}"
  }

  depends_on = [
    data.azurerm_subnet.azure_subnet_name,
    data.azurerm_private_dns_zone.acs_dns_zone,
    azurerm_search_service.acs
  ]
}

############ INFO ::: Provisioning of Azure Cognitive Search :: Completed ###############

resource "random_id" "acs_unique_id" {
  byte_length = 3
}

############ INFO ::: Provisioning of Azure App Configuration :: Started ###############

data "azurerm_private_dns_zone" "appconf_dns_zone" {
  count               = var.use_private_acs == "Y" ? 1 : 0
  name                = "privatelink.azconfig.io"
  resource_group_name = data.azurerm_virtual_network.VnetToBeUsed[0].resource_group_name
}

resource "azurerm_app_configuration" "appconf" {
  name                = var.acs_admin_app_config_name
  resource_group_name = "N" == var.acs_rg_YN ? azurerm_resource_group.acs_rg[0].name : var.acs_rg_name
  location            = "N" == var.acs_rg_YN ? azurerm_resource_group.acs_rg[0].location : var.azure_location
  sku                 = "standard"
  # public_network_access = var.use_private_acs == "Y" ? "Disabled" : "Enabled"

  depends_on = [
    azurerm_search_service.acs,
    data.azurerm_private_dns_zone.appconf_dns_zone
  ]
}

resource "null_resource" "disable_public_access" {
  provisioner "local-exec" {
    command = var.use_private_acs == "Y" ? "az appconfig update --name ${azurerm_app_configuration.appconf.name} --enable-public-network false --resource-group ${azurerm_app_configuration.appconf.resource_group_name}" : "echo 'INFO ::: App configuration is Public...'"
  }
  depends_on = [azurerm_app_configuration.appconf]
}

resource "azurerm_private_endpoint" "appconf_private_endpoint" {
  count               = var.use_private_acs == "Y" ? 1 : 0
  name                = "${azurerm_app_configuration.appconf.name}_private_endpoint"
  location            = data.azurerm_virtual_network.VnetToBeUsed[0].location
  resource_group_name = data.azurerm_virtual_network.VnetToBeUsed[0].resource_group_name
  subnet_id           = data.azurerm_subnet.azure_subnet_name[0].id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.appconf_dns_zone[0].id]
  }

  private_service_connection {
    name                           = "${azurerm_app_configuration.appconf.name}_connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_app_configuration.appconf.id
    subresource_names              = ["configurationStores"]
  }

  provisioner "local-exec" {
    command = "az resource wait --updated --ids ${self.subnet_id}"
  }

  depends_on = [
    data.azurerm_subnet.azure_subnet_name,
    data.azurerm_private_dns_zone.appconf_dns_zone,
    null_resource.disable_public_access
  ]
}

resource "azurerm_role_assignment" "appconf_dataowner" {
  scope                = azurerm_app_configuration.appconf.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azuread_service_principal.user.object_id

  depends_on = [
    azurerm_private_endpoint.appconf_private_endpoint
  ]
}

############ INFO ::: Provisioning of Azure App Configuration :: Completed ###############

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
    azurerm_app_configuration_key.destination_container_name
  ]
}

resource "azurerm_app_configuration_key" "acs_resource_group" {
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = "acs-resource-group"
  label                  = "acs-resource-group"
  value                  = azurerm_search_service.acs.resource_group_name

  depends_on = [
    azurerm_app_configuration_key.datasource_connection_string
  ]
}

resource "azurerm_app_configuration_key" "acs_service_name" {
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = "acs-service-name"
  label                  = "acs-service-name"
  value                  = azurerm_search_service.acs.name

  depends_on = [
    azurerm_app_configuration_key.acs_resource_group
  ]
}

resource "azurerm_app_configuration_key" "acs_api_key" {
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = "acs-api-key"
  label                  = "acs-api-key"
  value                  = azurerm_search_service.acs.primary_key

  depends_on = [
    azurerm_app_configuration_key.acs_service_name
  ]
}

resource "azurerm_app_configuration_key" "nmc_api_acs_url" {
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = "nmc-api-acs-url"
  label                  = "nmc-api-acs-url"
  value                  = "https://${azurerm_search_service.acs.name}.search.windows.net"

  depends_on = [
    azurerm_app_configuration_key.acs_api_key
  ]
}

output "appconf_dataowner_principal_id" {
  value = azurerm_role_assignment.appconf_dataowner.principal_id
}
