# Workload Identity, aka Federated Managed Identity

Example Terraform repo with GitHub Actions using federated Managed Identity and OpenID Connect (OIDC).

The federated identity credential creates a trust relationship between an application and an external identity provider (IdP).

You can then configure an external software workload to exchange a token from the external IdP for an access token from Microsoft identity platform.

Assumed a [Bash](https://learn.microsoft.com/windows/wsl/install) environment with [az](https://learn.microsoft.com/cli/azure/install-azure-cli-linux?pivots=apt), [git](https://github.com/git-guides/install-git) and [gh](https://cli.github.com/manual/installation) installed.

Check that you are logged into github.com using `gh auth status`. Not logged in? Use `gh auth login`.

Check that you are logged into Azure using `az account show`. Not logged in? Use `az login`. Wrong subscription? Use `az account set`.

## Fork the repo

Add fork step

## Clone the repo

```bash
git clone https://github.com/<yourGitHubID>/federated_managed_identity
```

```bash
cd federated_managed_identity
```

```bash
gitHubUser=$(git remote get-url origin | cut -f4 -d/)
gitHubRepo=$(git remote get-url origin | cut -f5 -d/)
```

## Defaults

The following command will save defaults local to the current working directory for region and resource group.

```bash
az config set --local defaults.location="UK South" defaults.group=terraform
```

These are used by the Azure CLI when you run commands from this directory.

## Resource Group

```bash
az group create --name "terraform"
```

## Managed Identity

Create a user assigned managed identity

```bash
az identity create --name "terraform"
identityId=$(az identity show --name "terraform" --query id --output tsv)
```

Assign the Contributor role at the subscription scope

```bash
az role assignment create \
  --assignee "$(az identity show --name "terraform" --query principalId --output tsv)" \
  --role "Contributor" \
  --scope "/subscriptions/$(az account show --query id --output tsv)"
```

Add the federated identity credential

```bash
az identity federated-credential create --name "terraform-github" --identity-name "terraform" \
  --issuer 'https://token.actions.githubusercontent.com'\
  --subject "repo:$gitHubUser/$gitHubRepo:ref:refs/heads/main"\
  --audiences 'api://AzureADTokenExchange'
```

Permitted subject claims for GitHub

* `repo:$gitHubUser/$gitHubRepo:environment:my-env`
* `repo:$gitHubUser/$gitHubRepo:ref:refs/heads/my-branch`
* `repo:$gitHubUser/$gitHubRepo:ref:refs/tags/my-tag`
* `repo:$gitHubUser/$gitHubRepo:pull-request`
* `$environment:job_workflow_ref:$organisation/$gitHubRepo/.github/workflows/$workflow.yaml@refs/heads/main`

<https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims>

## Storage Account

Generate a predictable 8 character hash from the resource group's resource ID. This will be used to help the storage account FQDN to be globally unique.

```bash
groupid=$(az group show --name terraform --query id --output tsv)
hash=$(echo "$groupid" | sha256sum | cut -c1-8)
```

```bash
az storage account create --name "terraform$hash" \
  --identity-type UserAssigned --user-identity-id $identityId \
  --sku Standard_RAGZRS \
  --min-tls-version TLS1_2 --allow-blob-public-access false
```

```bash
az storage container create --name tfstate \
  --account-name terraform$hash --auth-mode login
```

```bash
storageId=$(az storage account show --name "terraform$hash" --query id --output tsv)
```

## Create a Terraform Backend file

This is (close to) the format for the [provider for service principals with OIDC](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc) and the [backend when authenticating using OIDC](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm):

```bash
cat <<EOT > terraform/backend.tf
terraform {
  backend "azurerm" {
    use_oidc             = true

    tenant_id            = "$(az account show --query tenantId --output tsv)"
    subscription_id      = "$(az account show --query id --output tsv)"
    resource_group_name  = "terraform"

    storage_account_name = "terraform$hash"
    container_name       = "tfstate"
    key                  = "$gitHubRepo"
  }
}
EOT
```

Example backend.tf file:

```hcl
terraform {
  backend "azurerm" {
    use_oidc             = true

    tenant_id            = "3c584bbd-915f-4c70-9f2e-7217983f22f6"
    subscription_id      = "9b7a166a-267f-45a5-b480-7a04cfc1edf6"
    resource_group_name  = "terraform"

    storage_account_name = "terraform66615a0f"
    container_name       = "tfstate"
    key                  = "federated_managed_identity"
  }
}
```

## Create the GitHub secrets

```bash
gh secret set ARM_CLIENT_ID --body $(az identity show --name "terraform" --query clientId --output tsv)
gh secret set ARM_SUBSCRIPTION_ID --body $(az account show --query id --output tsv)
gh secret set ARM_TENANT_ID --body $(az identity show --name "terraform" --query tenantId --output tsv)
gh secret set ARM_BACKEND_RESOURCEGROUP --body $(az config get --local defaults.group --query value --output tsv --only-show-errors)
gh secret set ARM_BACKEND_STORAGEACCOUNT --body "terraform$hash"

```

## References

Info on workload identity federation - includes managed applications as well as service principals - <https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation>

This is the page for appIds - <https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation-create-trust>

And THIS IS THE ONE for managed identity - <https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation-create-trust-user-assigned-managed-identity>

Needs Contributor or [Managed Identity Contributor](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#managed-identity-contributor)

Others:

* Official GitHub to Azure is just OpenId on appId and also Service Principal - <https://learn.microsoft.com/azure/developer/github/connect-from-azure>
* Limitations - <https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation-considerations>
* [Permit IPs for GitHub Actions](https://stackoverflow.com/questions/68070211/which-ips-to-allow-in-azure-for-github-actions) - to be added
* <https://github.com/hashicorp/setup-terraform>
* <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc>
