locals {
  domain_name = var.use_prefix ? join("", [lower(var.domain_prefix), lower(var.domain_name), "-", lower(random_id.acs_unique_id.hex)]) : lower(var.domain_name)
  inside_vpc  = length(var.vpc_options["subnet_ids"]) > 0 ? true : false
}

# Create a resource group for security
resource "azurerm_resource_group" "security-rg" {
  name     = "security-${var.environment}-rg"
  location = var.location
}


resource "azurerm_resource_group" "acs_rg" {
  name     = var.acs_rg_name
  location = var.acs_region
}

resource "azurerm_search_service" "acs" {
  name                = var.acs_srv_name
  resource_group_name = azurerm_resource_group.acs_rg.name
  location            = azurerm_resource_group.acs_rg.location
  sku                 = "standard"

  tags = merge(
    {
      "Domain" = lower(local.domain_name)
    },
    var.tags,
  )

}

resource "random_id" "acs_unique_id" {
  byte_length = 3
}

resource "azurerm_key_vault" "acs_key_vault" {
  name                        = "azureacskeyvault"
  location                    = azurerm_resource_group.acs_rg.location
  resource_group_name         = azurerm_resource_group.acs_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}