# 06 - Development Sign-in and Governance

**Status:** Completed. User sign-in registration, a budget, and Azure Policy are in place for the development foundation and the non-production subscription.

**Execution:** Peter edited the configuration in Visual Studio Code and ran all commands, guided by Claude. All resources were created with Terraform from `infra/environments/development/layer-0-foundation/`. Azure Policy is defined in a separate file, `policy.tf`.

## Entra ID app registration

| Resource | Name | Configuration |
| --- | --- | --- |
| App registration | `app-sits-dev` | Single tenant. Redirect URI `https://app.dev.sits.internal/.auth/login/aad/callback`. ID token issuance enabled. Microsoft Graph delegated permission User.Read. |
| Federated credential | `app-managed-identity` | Trusts the application managed identity `id-sits-dev-app-swc` (subject: its principal identifier). No client secret exists. |
| Enterprise application | `app-sits-dev` | Assignment required: Yes. Unassigned users are rejected by Entra ID (AADSTS50105). |
| Security group | `grp-sits-dev-app-users` | Assigned to the application with the default role. Members are added later (test users `app-user` and `app-denied` are postponed). |

The AzureAD provider (`hashicorp/azuread`, version 3.x) was added for Entra ID resources. The provider lock file is committed.

## Budget

| Resource | Configuration |
| --- | --- |
| `budget-sits-nonprod` | Monthly budget on the whole non-production subscription (Dev and Test). E-mail alerts at 80 % and 100 % of actual cost and at 100 % of forecasted cost. The amount and recipient are kept in the ignored `development.tfvars`. A budget sends alerts only; it does not stop resources. |

## Azure Policy (non-production subscription)

| Assignment | Built-in definition | Enforcement |
| --- | --- | --- |
| `sits-nonprod-allowed-locations` | Allowed locations: Sweden Central and `global` | Deny |
| `sits-nonprod-tag-environment` | Require a tag on resources: `environment` | Report only (DoNotEnforce) |
| `sits-nonprod-tag-owner` | Require a tag on resources: `owner` | Report only (DoNotEnforce) |
| `sits-nonprod-tag-costcenter` | Require a tag on resources: `costCenter` | Report only (DoNotEnforce) |
| `sits-nonprod-webapp-https` | App Service apps should only be accessible over HTTPS | Audit |
| `sits-nonprod-webapp-tls` | App Service apps should use the latest TLS version | Audit if not exists |
| `sits-nonprod-keyvault-no-public-access` | Azure Key Vault should disable public network access | Deny |

`global` is allowed because private DNS zones use that location. Tag policies only report, because Azure creates some resources without tags (for example, network interfaces of private endpoints). Enforcement can follow the audit, as described in the design.

| Exemption (category Waiver) | Scope | Reason |
| --- | --- | --- |
| `exempt-locations-network-watcher` | `NetworkWatcherRG` | Created automatically by Azure in North Europe |
| `exempt-locations-azure-devops` | Azure DevOps billing resource group | Created automatically by Azure DevOps in West Europe |
| `exempt-keyvault-public-cert` | Certificate vault | Approved deviation recorded in step 04 |
| `exempt-keyvault-public-admin` | Admin vault | Approved deviation recorded in step 04 |

The application Key Vault has no exemption and must be private.

## Checks

| Check | Result |
| --- | --- |
| `az ad sp list` | `app-sits-dev` with assignment required: True |
| `az ad app federated-credential list` | `app-managed-identity` with the principal identifier of `id-sits-dev-app-swc` |
| `az consumption budget show` | `budget-sits-nonprod`, monthly |
| `az policy assignment list` | Seven assignments; tag assignments DoNotEnforce, others Default |
| Terraform plans | Only the expected new resources; no changes to existing resources |

## Issues and fixes

- The first apply of the policy exemptions for the two vaults failed with HTTP 409 `CheckAccessPrincipalCreationConcurrencyError`, a transient Azure error under parallel requests. A second apply after a short wait created both exemptions.
- Unsaved files (`variables.tf`, `development.tfvars`) caused Terraform to ask for variable values. Saving the files resolved it.

## Decisions

- Custom lock roles (Lock Creator, Lock Remover) are created with the production foundation, because the delete lock is used only in production.
- PIM and Conditional Access are configured with the production foundation, because they protect the production administrator account.
- Azure Policy for the non-production subscription lives in the development foundation, because Dev and Test share the subscription.

## Repository work

| Commit | Content |
| --- | --- |
| `2b5fdf3` | Entra ID app registration, federated credential, user group, assignment, and the AzureAD provider |
| `aeb2aa4` | Monthly budget with alerts |
| `c2787ca` | Azure Policy assignments and exemptions (`policy.tf`) |

## Next step

Proposed: development layer 1 (network and operations). The approach for the first build is to be decided by Peter.