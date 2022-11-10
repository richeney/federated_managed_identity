
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.30.0" // Support for OpenID Connect added in version 3.7.0
    }
  }

  backend "azurerm" {
    use_oidc = true

    tenant_id            = "3c584bbd-915f-4c70-9f2e-7217983f22f6"
    subscription_id      = "9b7a166a-267f-45a5-b480-7a04cfc1edf6"
    resource_group_name  = "terraform"
    storage_account_name = "terraform66615a0f"

    container_name = "tfstate"
    key            = "federated_managed_identity"
  }
}

provider "azurerm" {
  features {}

  // tenant_id       = "3c584bbd-915f-4c70-9f2e-7217983f22f6"
  // subscription_id = "9b7a166a-267f-45a5-b480-7a04cfc1edf6"
  // client_id       = "8fbf5ac1-d1e4-47a3-8f6a-cb9e9b72ab0e"

  use_oidc = true
  //oidc_request_token = var.oidc_request_token
  //oidc_request_url   = var.oidc_request_url

  storage_use_azuread = true
}
