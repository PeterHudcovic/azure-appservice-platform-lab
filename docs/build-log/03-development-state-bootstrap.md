# 03 - Development State Bootstrap

**Status:** Completed. The development foundation layer stores its Terraform state (infrastructure state) in Azure.

**Execution:** Peter edited the configuration in Visual Studio Code and ran all commands, guided by Claude. All Azure resources in this step were created with Terraform from `infra/environments/development/layer-0-foundation/`. Results were confirmed by Peter with CLI (Command-Line Interface) output and Azure portal screenshots during the session.

## Resources created

| Resource | Name | Configuration |
| --- | --- | --- |
| Resource group | `rg-sits-dev-foundation-swc` | Sweden Central. Tags `environment`, `owner`, `costCenter`. |
| Storage account | `stsitstfdevswc` | Standard, LRS (Locally Redundant Storage), StorageV2. HTTPS only, minimum TLS (Transport Layer Security) 1.2. Shared key access disabled, Microsoft Entra ID authorization by default in the portal, anonymous blob access disabled, local users disabled. Blob versioning, 7-day blob and container soft delete. Protected with `prevent_destroy`. |
| Containers | `tfstate-layer0`, `tfstate-layer1`, `tfstate-layer2` | Private. One container per layer. |
| Role assignment | Storage Blob Data Contributor on `tfstate-layer0` only | Assigned to the identity that runs Terraform for layer 0 (the Lab Admin account). |

The public network endpoint of the storage account stays enabled by design, so that a Microsoft-hosted agent can manage layer 1. Access to state data requires Microsoft Entra ID sign-in and a data role.

## Bootstrap approach

1. The first apply used local state, because the storage account did not exist yet.
2. A `backend "azurerm"` block was added with `use_azuread_auth = true`. The subscription identifier is supplied from an ignored local file `backend.hcl` (partial backend configuration). `backend.example.hcl` shows the expected format.
3. `terraform init -backend-config="backend.hcl" -migrate-state` copied the state to the blob `development-layer0.tfstate` in `tfstate-layer0`.
4. The local state files were moved outside the repository.

The provider uses `storage_use_azuread = true`, because shared key access is disabled.

## Checks

| Check | Result |
| --- | --- |
| `terraform validate` | Configuration valid |
| Plan before the first apply | 5 to add, 0 to change, 0 to destroy |
| First apply | 5 added |
| Storage account settings in the portal | Match the configuration |
| Blob listing in `tfstate-layer0` before the data role | Denied for Microsoft Entra ID sign-in (expected) |
| Blob listing after the data role | Allowed. Access control shows the role on the container scope only. |
| `terraform state list` after migration | All 7 entries present |
| State blob in the portal | `development-layer0.tfstate` present, versioning active |
| Plan after migration and after removing local state | No changes. State lock acquired and released. |

## Issue and fix

Azure CLI was signed in with Peter's personal account, while the portal used the Lab Admin account. The subscription list looked the same for both accounts, so the mismatch was not detected. The role assignment, which uses the identity running Terraform, was therefore given to the personal account. After signing in to Azure CLI as Lab Admin, a new plan replaced the role assignment (1 added, 1 destroyed), and the portal confirmed access for Lab Admin.

Lesson: before each Terraform run, check the signed-in account:

`az ad signed-in-user show --query "{name:displayName, upn:userPrincipalName}" --output table`

## Observations

- Azure created two resource groups automatically in the non-production subscription: `NetworkWatcherRG` (North Europe) and a resource group for Azure DevOps billing (West Europe). Terraform does not manage them. The planned region policy must account for them.
- The storage account contains the system container `$logs`, created by Azure.
- The personal account still has the Owner role on the subscriptions. Review after the lab is stable.

## What this record does not establish

No network, application, identity, monitoring, policy, or pipeline resources exist yet. Pipeline identities do not have access to the state containers yet. No isolation tests were performed.

## Repository work

Commit `4c7b647`: `main.tf`, `providers.tf`, `backend.tf`, and `backend.example.hcl` in the development foundation layer.

## Next step

Proposed: further development foundation resources (resource groups for layers 1 and 2, permanent managed identities, monitoring, package storage, a static public IP address for NAT, and the certificate and admin vaults). They start after Peter assigns them.