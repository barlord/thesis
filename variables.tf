variable "regions" {
  description = "List of regions to deploy the resources"
  type        = list(string)
  default     = ["spaincentral", "westeurope", "centralindia"]
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg-thesis"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 1
}

variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. Set this value if you're running this example using Managed Identity as the authentication method."
  default     = null
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azureadmin"
}


variable "vnet_name" {
  description = "The name of the virtual network."
  type        = string
  default     = "vnet-thesis"
}

variable "subnet_name" {
  description = "The name of the subnet."
  type        = string
  default     = "subnet-thesis"
}

variable "subnet_address_prefix" {
  description = "The address prefix to use for the subnet."
  type        = list(string)
  default     = ["10.1.1.0/24"]
}

variable "service_endpoints" {
  description = "The list of Service endpoints to associate with the subnet."
  type        = list(string)
  default     = ["Microsoft.Storage"]
}

variable "address_space" {
  description = "The address space that is used by the virtual network."
  type        = list(string)
  default     = ["10.1.0.0/16"]
}
