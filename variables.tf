variable "resource_group_name" {
  description = "Name for the resource group"
  type        = string
  default     = "federated_managed_identity"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "container_group_name" {
  description = "Name of the container group"
  type        = string
  default     = "federated_managed_identity"
}
