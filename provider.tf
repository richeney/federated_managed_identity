
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.30.0" // Support for OpenID Connect added in version 3.7.0
    }
  }

  backend "azurerm" {
    use_oidc = true
    # tenant_id            = // ARM_TENANT_ID
    # subscription_id      = // ARM_SUBSCRIPTION_ID
    # resource_group_name  = Set in the workflow with --backend-config
    # storage_account_name = Set in the workflow with --backend-config
    container_name = "tfstate"
    key            = "federated_managed_identity"
  }
}

provider "azurerm" {
  features {}
  # tenant_id           = // ARM_TENANT_ID
  # subscription_id     = // ARM_SUBSCRIPTION_ID
  # client_id           = // ARM_CLIENT_ID
  use_oidc            = true
  storage_use_azuread = true
}
