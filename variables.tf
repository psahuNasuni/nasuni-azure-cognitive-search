########################################################
##  Developed By  :   Pradeepta Kumar Sahu
##  Project       :   Nasuni Azure Cognitive Search Integration
##  Organization  :   Nasuni Labs   
#########################################################

variable "acs_domain_name" {
  description = "Domain name for Azure Cognitive Search"
  type        = string
  default     = "acs"
}

variable "acs_resource_group" {
  description = "Resouce group name for Azure Cognitive Search"
  type        = string
  default     = ""
}

variable "acs_service_name" {
  description = "Service name for Azure Cognitive Search"
  type        = string
  default     = ""
}

variable "azure_location" {
  description = "Region for Azure Cognitive Search"
  type        = string
  default     = ""
}

variable "acs_version" {
  description = "Version of Azure Cognitive Search to deploy (default 7.10)"
  type        = string
  default     = "7.10"
}

variable "tags" {
  description = "tags to apply to all resources"
  type        = map(string)
  default = {
    Application     = "Nasuni Analytics Connector with Azure Cognitive Search"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Community Tool"
    Version         = "V 0.1"
  }
}

variable "use_prefix" {
  description = "Flag indicating whether or not to use the domain_prefix. Default: true"
  type        = bool
  default     = true
}

variable "domain_prefix" {
  description = "String to be prefixed to search domain. Default: nasuni-labs-"
  type        = string
  default     = "nasuni-labs-"
}

variable "vpc_options" {
  description = "A map of supported vpc options"
  type        = map(list(string))

  default = {
    security_group_ids = []
    subnet_ids         = []
  }
}

variable "sp_application_id" {
  description = "User Principal Application ID"
  type        = string
  default     = ""
}

variable "cognitive_search_YN" {
  description = "cognitive_search_status"
  default     = ""
}

variable "acs_app_config_YN" {
  description = "acs app_config status"
  default     = ""
}

variable "acs_rg_name" {
  description = "acs_rg_name"
  default     = ""
}

variable "acs_rg_YN" {
  description = "acs resource group available: Y/N"
  default     = ""
}

variable "acs_admin_app_config_name" {
  description = "acs admin app_config"
  default     = ""
}

variable "networking_resource_group" {
  description = "Resouce group name for Azure Cognitive Search"
  type        = string
  default     = ""
}

variable "user_vnet_name" {
  description = "Virtual Network Name for Azure Cognitive Search"
  type        = string
  default     = ""
}

variable "user_subnet_name" {
  description = "Available subnet name in Virtual Network"
  type        = string
  default     = ""
}

variable "use_private_acs" {
  description = "Use Private ACS"
  type        = string
  default     = "N"
}
