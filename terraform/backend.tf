terraform {
  backend "azurerm" {
    resource_group_name  = "terraform"
    storage_account_name = "terraform66615a0f"
    container_name       = "tfstate"
    key                  = "federated_managed_identity"
  }
}
