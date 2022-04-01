locals {
  domain_name = var.use_prefix ? join("", [lower(var.domain_prefix), lower(var.domain_name), "-", lower(random_id.acs_unique_id.hex)]) : lower(var.domain_name)
  inside_vpc  = length(var.vpc_options["subnet_ids"]) > 0 ? true : false
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

