data "azurerm_client_config" "current" {}

locals {
  acs_domain_name = var.use_prefix ? join("", [lower(var.domain_prefix), lower(var.acs_domain_name), "-", lower(random_id.acs_unique_id.hex)]) : lower(var.acs_domain_name)
  inside_vpc  = length(var.vpc_options["subnet_ids"]) > 0 ? true : false
}

data "azuread_user" "user"{
user_principal_name = var.user_principal_name
}

resource "azurerm_resource_group" "acs_rg" {
  count = "N" == var.acs_rg_YN ? 1 : 0
  name     = "nasuni-labs-acs-rg"
  location = var.azure_location
}

resource "azurerm_search_service" "acs" {
  name                = "${local.acs_domain_name}"
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

resource "azurerm_key_vault" "acs_admin_vault" {
  count = "N" == var.acs_key_vault_YN ? 1 : 0
  ### Purpose : to Store details of ACS service
  name                        = "nasuni-labs-acs-admin"
  location                    = azurerm_resource_group.acs_rg[0].location
  resource_group_name         = azurerm_resource_group.acs_rg[0].name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azuread_user.user.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "Set",
      "List",
      "Delete",
      "Purge",
      "Recover"
    ]

    storage_permissions = [
      "Get",
    ]
  }

  depends_on = [
    azurerm_search_service.acs
  ]
}

resource "azurerm_key_vault_secret" "acs-url" {
  ### If ACS admin key vault  = N create a Version of entry in KeyVault
  count        = "N" == var.cognitive_search_YN ? 1 : 0
  name         = "nmc-api-acs-url"
  value        = "https://${azurerm_search_service.acs.name}.search.windows.net"
  key_vault_id = "N" == var.cognitive_search_YN ? azurerm_key_vault.acs_admin_vault[0].id : var.acs_key_vault_id

  depends_on = [
    azurerm_key_vault.acs_admin_vault,azurerm_search_service.acs
  ]
}

resource "azurerm_key_vault_secret" "acs-api-key" {
  count        = "N" == var.cognitive_search_YN ? 1 : 0
  name         = "acs-api-key"
  value        = azurerm_search_service.acs.primary_key
  key_vault_id = "N" == var.cognitive_search_YN ? azurerm_key_vault.acs_admin_vault[0].id : var.acs_key_vault_id

  depends_on = [
    azurerm_key_vault.acs_admin_vault
  ]
}

resource "azurerm_key_vault_secret" "acs_service_name_per" {
  count        = "N" == var.cognitive_search_YN ? 1 : 0
  name         = "acs-service-name"
  value        = azurerm_search_service.acs.name
  # key_vault_id = azurerm_key_vault.acs_admin_vault[0].id
  key_vault_id = "N" == var.cognitive_search_YN ? azurerm_key_vault.acs_admin_vault[0].id : var.acs_key_vault_id

}
resource "azurerm_key_vault_secret" "acs_resource_group_per" {
  count       = "N" == var.cognitive_search_YN ? 1 : 0
  name         = "acs-resource-group"
  value        = azurerm_search_service.acs.resource_group_name
  key_vault_id = "N" == var.cognitive_search_YN ? azurerm_key_vault.acs_admin_vault[0].id : var.acs_key_vault_id

}


resource "azurerm_key_vault_secret" "datasource-connection-string" {
  name         = "datasource-connection-string"
  value        = var.datasource_connection_string
  key_vault_id = "N" == var.cognitive_search_YN ? azurerm_key_vault.acs_admin_vault[0].id : var.acs_key_vault_id

  depends_on = [
    azurerm_key_vault.acs_admin_vault
  ]
}
resource "azurerm_key_vault_secret" "destination-container-name" {
  name         = "destination-container-name"
  value        = var.destination_container_name
  key_vault_id = "N" == var.cognitive_search_YN ? azurerm_key_vault.acs_admin_vault[0].id : var.acs_key_vault_id

  depends_on = [
    azurerm_key_vault.acs_admin_vault
  ]
}
