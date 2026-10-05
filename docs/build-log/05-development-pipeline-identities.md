# 05 - Development Pipeline Identities

**Status:** Completed. Five Azure DevOps service connections authenticate to Azure without secrets.

**Execution:** Peter edited the configuration in Visual Studio Code, ran all Terraform commands, and created the service connections in the Azure DevOps portal, guided by Claude. Identities, role assignments, and federated credentials were created with Terraform from `infra/environments/development/layer-0-foundation/`.

## Approach

Each pipeline task has its own user-assigned managed identity with only the permissions it needs. Each identity trusts exactly one Azure DevOps service connection through workload identity federation. No client secret exists.

1. Terraform created the identities and their role assignments.
2. In Azure DevOps, each service connection was created as a draft with the identity type "App registration or managed identity (manual)" and the credential "Workload identity federation". Azure DevOps generated the issuer and the subject identifier.
3. The subject identifiers were added to the ignored local file `development.tfvars` (variable `pipeline_federation_subjects`). Terraform created one federated credential per identity. The issuer is derived from the tenant.
4. Each service connection was completed with "Verify and save".

"Grant access permission to all pipelines" is disabled on every service connection.

## Identities and permissions

| Service connection | Identity | Data roles | Management roles |
| --- | --- | --- | --- |
| `dev-infra-l1` | `id-sits-dev-infra-l1-swc` | Storage Blob Data Contributor on `tfstate-layer1` | Contributor on `rg-sits-dev-network-swc` |
| `dev-infra-l2` | `id-sits-dev-infra-l2-swc` | Storage Blob Data Contributor on `tfstate-layer2` | Contributor on `rg-sits-dev-app-swc` and `rg-sits-dev-kv-swc` |
| `dev-deploy` | `id-sits-dev-deploy-swc` | Storage Blob Data Reader on `packages` | None yet. The Web App role is added with layer 2. |
| `dev-destroy` | `id-sits-dev-destroy-swc` | Storage Blob Data Contributor on `tfstate-layer1` and `tfstate-layer2` | Contributor on the network, application, and Key Vault resource groups |
| `build` | `id-sits-build-swc` | Storage Blob Data Contributor on `packages` | None |

No pipeline identity has access to `tfstate-layer0`. Layer 0 is managed only by Lab Admin.

The roles are defined as tables in Terraform locals (`pipeline_data_roles`, `pipeline_management_roles`), so the permissions of every identity are visible in one place.

## Checks

| Check | Result |
| --- | --- |
| Plan before each apply | Only new resources; the `moved` block kept the existing `dev-infra-l1` credential without replacement |
| `az identity list` | Five pipeline identities present |
| Subject identifiers in `development.tfvars` | Five different values, each ending with the identifier of its service connection |
| Azure DevOps "Verify and save" | Succeeded for all five service connections |
| Repository | No subject identifiers or service connection identifiers committed |

## Issues and fixes

- AzureRM provider 5.7 changed `azurerm_federated_identity_credential`: `parent_id` is now `user_assigned_identity_id`, and `resource_group_name` was removed. `terraform validate` reported the difference before anything was sent to Azure.
- The first service connection was created with a single resource. Moving to one resource for all five used a `moved` block, so Terraform did not recreate the working credential.
- An unsaved `variables.tf` caused Terraform to ask for the old variable. Saving the file resolved it.

## What this record does not establish

No pipeline has run yet. Branch checks, approvals, pipeline permissions on the service connections, and the private agent pools are configured with the pipelines. Custom roles from the design (subnet join, Private DNS zones, managed identity operator, lock roles, conditional role assignment) are added with layers 1 and 2.

## Repository work

| Commit | Content |
| --- | --- |
| `48b7ff0` | Pipeline identities and state and package data roles |
| `86ea3d6` | Federated credential and network role for `dev-infra-l1` |
| `69b78e8` | Federated credentials for all pipeline identities and layer management roles |

## Next step

Proposed: the Entra ID app registration for user sign-in to the application, and the custom lock roles. They start after Peter assigns them.