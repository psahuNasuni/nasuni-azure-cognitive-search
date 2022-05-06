data "azurerm_client_config" "current" {}

locals {
  acs_domain_name = var.use_prefix ? join("", [lower(var.domain_prefix), lower(var.acs_domain_name), "-", lower(random_id.acs_unique_id.hex)]) : lower(var.acs_domain_name)
  inside_vpc  = length(var.vpc_options["subnet_ids"]) > 0 ? true : false
}

resource "azurerm_resource_group" "acs_rg" {
  name     = var.acs_resource_group
  location = var.azure_location
}

resource "azurerm_search_service" "acs" {
  name                = var.acs_srv_name
  resource_group_name = azurerm_resource_group.acs_rg.name
  location            = azurerm_resource_group.acs_rg.location
  sku                 = "standard"

  tags = merge(
    {
      "Domain" = lower(local.acs_domain_name)
    },
    var.tags,
  )

}


resource "random_id" "acs_unique_id" {
  byte_length = 3
}

resource "azurerm_key_vault" "acs_key_vault" {
  name                        = "nasuni-api-acs-key-vault"
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
  name         = "nmc-api-acs-url"
  value        = "https://${var.acs_service_name}.search.windows.net"
  key_vault_id = azurerm_key_vault.acs_key_vault.id

  depends_on = [
    azurerm_key_vault.acs_key_vault
  ]
}

resource "azurerm_key_vault_secret" "acs-api-key" {
  name         = "acs-api-key"
  value        = azurerm_search_service.acs.primary_key
  key_vault_id = azurerm_key_vault.acs_key_vault.id

  depends_on = [
    azurerm_key_vault.acs_key_vault
  ]
}
resource "azurerm_key_vault_secret" "datasource-Connection-String" {
  name         = "datasource-Connection-String"
  value        = "https;AccountName=destinationbktsa;AccountKey=ekOsyrbVEGCbOQFIM6CaM3Ne7zdnct33ZuvSvp1feo1xtpQ/IMq15WD9TGXIeVvvuS0DO1mRMYYB+ASt1lMVKw==;EndpointSuffix=core.windows.net"
  key_vault_id = azurerm_key_vault.acs_key_vault.id

  depends_on = [
    azurerm_key_vault.acs_key_vault
  ]
}
resource "azurerm_key_vault_secret" "destination-container-name" {
  name         = "destination-container-name"
  value        = "destinationbkt"
  key_vault_id = azurerm_key_vault.acs_key_vault.id

  depends_on = [
    azurerm_key_vault.acs_key_vault
  ]
}


resource "null_resource" "acs_data" {
  provisioner "local-exec" {
    command = "sh acs_output.sh ${local.acs_endpoint} ${local.acs_api_key} ${local.datasourceConnectionString} ${local.destination_container_name} "
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf *.txt"
  }
  depends_on = [
    azurerm_search_service.acs
  ]
}

locals {
    acs_endpoint="https://${azurerm_search_service.acs.name}.search.windows.net" 
    acs_api_key="${azurerm_search_service.acs.primary_key}"
    datasourceConnectionString="DefaultEndpointsProtocol=https;AccountName=destinationbktsa;AccountKey=ekOsyrbVEGCbOQFIM6CaM3Ne7zdnct33ZuvSvp1feo1xtpQ/IMq15WD9TGXIeVvvuS0DO1mRMYYB+ASt1lMVKw==;EndpointSuffix=core.windows.net"
    destination_container_name="destinationbkt"
    depends_on = [null_resource.acs_data]
}


