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

Add the federated identity credential

```bash
az identity federated-credential create --name "terraform-github" --identity-name "terraform" \
  --issuer 'https://token.actions.githubusercontent.com/'\
  --subject "repo:$gitHubUser/$gitHubRepo:environment:Testing"\
  --audiences 'api://AzureADTokenExchange'
```

> Subject could be repo:$gitHubUser/$gitHubRepo:ref:refs/heads/main" if not using environments

## Storage Account

Generate a 8 character hash

```bash
groupid=$(az group show --name terraform --query id --output tsv)
uniq=$(echo "$groupid" | sha256sum | cut -c1-8)
```

```bash
az storage account create --name "terraform$uniq" --identity-type UserAssigned --user-identity-id $identityId --sku Standard_RAGZRS --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create --name tfstate2 --account-name terraform$uniq --auth-mode login
```

```bash
storageId=$(az storage account show --name "terraform$uniq" --query id --output tsv)

```

az rest --method POST --uri 'https://graph.microsoft.com/applications/f6475511-fd81-4965-a00e-41e7792b7b9c/federatedIdentityCredentials' --body '{"name":"Testing","issuer":"https://token.actions.githubusercontent.com/","subject":"repo:octo-org/octo-repo:environment:Production","description":"Testing","audiences":["api://AzureADTokenExchange"]}'

{
  "@odata.context": "https://graph.microsoft.com/$metadata#applications('f6475511-fd81-4965-a00e-41e7792b7b9c')/federatedIdentityCredentials/$entity",
  "audiences": [
    "api://AzureADTokenExchange"
  ],
  "description": "Testing",
  "id": "1aa3e6a7-464c-4cd2-88d3-90db98132755",
  "issuer": "https://token.actions.githubusercontent.com/",
  "name": "Testing",
  "subject": "repo:octo-org/octo-repo:environment:Production"
}

name: The name of your Azure application.

issuer: The path to the GitHub OIDC provider: https://token.actions.githubusercontent.com/. This issuer will become trusted by your Azure application.

subject: Before Azure will grant an access token, the request must match the conditions defined here.

For Jobs tied to an environment: repo:< Organization/Repository >:environment:< Name >

For Jobs not tied to an environment, include the ref path for branch/tag based on the ref path used for triggering the workflow: repo:< Organization/Repository >:ref:< ref path>. For example, repo:n-username/ node_express:ref:refs/heads/my-branch or repo:n-username/ node_express:ref:refs/tags/my-tag.

For workflows triggered by a pull request event: repo:< Organization/Repository >:pull-request.
audiences lists the audiences that can appear in the external token. This field is mandatory. The recommended value is "api://AzureADTokenExchange".



audience `api://AzureADTokenExchange`


##


## Remote State



## User-Assigned Managed Identity



## References



Info on workload identity federation - includes managed applications aswell as service principals - <https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation>

This is the page for appIds - <https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust>

And THIS IS THE ONE for managed identity - <https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust-user-assigned-managed-identity>

Needs Contributor or [Managed Identity Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#managed-identity-contributor)

Contributor
    {
      "actions": [
        "*"
      ],
      "notActions": [
        "Microsoft.Authorization/*/Delete",
        "Microsoft.Authorization/*/Write",
        "Microsoft.Authorization/elevateAccess/Action",
        "Microsoft.Blueprint/blueprintAssignments/write",
        "Microsoft.Blueprint/blueprintAssignments/delete",
        "Microsoft.Compute/galleries/share/action"
      ],
      "dataActions": [],
      "notDataActions": []
    }

Managed Identity Contributor
    {
      "actions": [
        "Microsoft.ManagedIdentity/userAssignedIdentities/read",
        "Microsoft.ManagedIdentity/userAssignedIdentities/write",
        "Microsoft.ManagedIdentity/userAssignedIdentities/delete",
        "Microsoft.Authorization/*/read",
        "Microsoft.Insights/alertRules/*",
        "Microsoft.Resources/subscriptions/resourceGroups/read",
        "Microsoft.Resources/deployments/*",
        "Microsoft.Support/*"
      ],
      "notActions": [],
      "dataActions": [],
      "notDataActions": []
    }

Official GitHub to Azure is just OpenId on appId and also Service Principal - <https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure>

Limitations - <https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-considerations>

* [Passwordless Github Actions with Azure Workload Identity OIDC](https://www.youtube.com/watch?v=7iCtY0ztYY4) - Houssem Dellai

* [Permit IPs for GitHub Actions](https://stackoverflow.com/questions/68070211/which-ips-to-allow-in-azure-for-github-actions)