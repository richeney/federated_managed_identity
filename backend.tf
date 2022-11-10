terraform {
  backend "azurerm" {
    use_oidc             = true

    // tenant_id            = "3c584bbd-915f-4c70-9f2e-7217983f22f6"
    // subscription_id      = "9b7a166a-267f-45a5-b480-7a04cfc1edf6"
    resource_group_name  = "terraform"

    storage_account_name = "terraform66615a0f"
    container_name       = "tfstate"
    key                  = "federated_managed_identity"
  }
}