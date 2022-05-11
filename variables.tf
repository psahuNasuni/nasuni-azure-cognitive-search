########################################################
##  Developed By  :   Pradeepta Kumar Sahu
##  Project       :   Nasuni Azure Cognitive Search Integration
##  Organization  :   Nasuni Labs   
#########################################################

variable "acs_domain_name" {
  description = "Domain name for Azure Cognitive Search"
  type        = string
  default     = "domain"
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


variable "datasource-connection-string" {
  description = "Datasource Service Account Connection Stringe"
  type        = string
  default     = ""
}

variable "destination-container-name" {
  description = "Destination Container name"
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

variable "acs_key_vault" {
  description = "Azure Key Vault name for Azure Cognitive Search"
  type        = string
  default     = "nasuniacssecretstore"
}
