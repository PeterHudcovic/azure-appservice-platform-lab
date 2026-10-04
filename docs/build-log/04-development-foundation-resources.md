# 04 - Development Foundation Resources

**Status:** Completed for the resources listed below. Further foundation resources remain (see Next step).

**Execution:** Peter edited the configuration in Visual Studio Code and ran all commands, guided by Claude. All resources were created with Terraform from `infra/environments/development/layer-0-foundation/`, using the remote state from step 03. Each block was planned, applied, checked, and committed separately.

## Resources created

| Block | Resource | Name | Notes |
| --- | --- | --- | --- |
| Resource groups | Resource group | `rg-sits-dev-network-swc` | Empty. Filled by layer 1. |
| | Resource group | `rg-sits-dev-app-swc` | Empty. Filled by layer 2. |
| | Resource group | `rg-sits-dev-kv-swc` | Empty. For the application Key Vault only, so that recovery rights can be scoped to one group. |
| Permanent identities | UAMI (User-Assigned Managed Identity) | `id-sits-dev-app-swc` | Application identity. Kept in layer 0 so that its principal identifier never changes. |
| | UAMI | `id-sits-dev-agw-swc` | Application Gateway identity. Same reason. |
| Monitoring | Log Analytics workspace | `log-sits-dev-swc` | PerGB2018, 30-day retention. |
| | Application Insights | `appi-sits-dev-swc` | Workspace-based, connected to the workspace above. |
| Package storage | Storage account | `stsitspkgswc` | Shared by all environments. Shared key access disabled, Microsoft Entra ID only, anonymous access disabled, local users disabled. Protected with `prevent_destroy`. |
| | Container | `packages` | Private. |
| | Immutability policy | on `packages` | 7 days. Unlocked; it will be locked after the build and deployment pipelines are verified. |
| NAT address | Public IP address | `pip-sits-dev-nat-swc` | Standard, static, zone 1, in `rg-sits-dev-network-swc`. Protected with `prevent_destroy`. The layer 1 NAT Gateway must use zone 1. |
| Vaults | Key Vault | `kv-sits-dev-cert-swc` | Certificate vault. RBAC (Role-Based Access Control) mode, 7-day soft delete, no purge protection in Dev, trusted service bypass disabled. Protected with `prevent_destroy`. |
| | Key Vault | `kv-sits-dev-adm-swc` | Admin vault for the Ops VM emergency password. Same settings. No data role assigned yet. |
| | Role assignment | Key Vault Secrets User on the certificate vault | Application Gateway identity. Scoped to that vault only. |
| | Role assignment | Key Vault Certificates Officer on the certificate vault | Lab Admin, to manage the WAF certificate. |
| Certificate | Key Vault certificate | `cert-app-dev` | Self-signed, `CN=app.dev.sits.internal`, RSA 2048, valid 12 months, automatic renewal disabled (notification 30 days before expiry). |

The provider now never purges soft-deleted Key Vaults on destroy and recovers them when they are created again.

## Checks

| Check | Result |
| --- | --- |
| Plan before each apply | Only the expected new resources; no changes to existing resources |
| Resource groups | `az group list`: four `rg-sits-dev-*` groups in Sweden Central |
| Managed identities | `az identity list`: two identities, each with its own principal identifier |
| Public IP address | `az network public-ip show`: static address assigned in zone 1 |
| Certificate | `az keyvault certificate show`: subject `CN=app.dev.sits.internal`, issuer `Self`, expiry in October 2027. This also confirmed the Certificates Officer role for Lab Admin. |

## Approved deviation from the design

Peter approved the following change, so that the lab can be presented from any network without changes on the day:

- The administrator address (`admin_ip`) is not used.
- The certificate vault and the admin vault accept public access from any address. Access still requires Microsoft Entra ID sign-in and a data role.
- The planned production Bastion rule becomes: deny HTTPS from the static NAT addresses of Dev and Test, then allow HTTPS from the internet. Dev and Test remain unable to reach production Bastion.
- The isolation test "Ops VM to the vaults" is then enforced by identity (no role), not by the network.

In a company, management access would be limited to fixed corporate addresses or a VPN (Virtual Private Network).

## Lab limitations recorded in this step

- The package storage is shared by all environments and lives in the non-production subscription. In a company it would be in a separate shared subscription, so that production does not depend on a less trusted environment.
- The administrator's internet connection uses carrier-grade NAT (Network Address Translation), so the public address is shared and can change. This was one reason for the approved deviation.
- The WAF certificate is self-signed. In a company it would be issued by the corporate certificate authority.

## Open items

- Decide how the public part of the WAF certificate reaches layer 1, because the Microsoft-hosted agent has no access to the certificate vault.
- Possible hardening: disable local authentication on Log Analytics and Application Insights.
- Lock the package immutability policy after the pipelines are verified.

## Repository work

| Commit | Content |
| --- | --- |
| `d14806b` | Resource groups for layers 1 and 2 and the application Key Vault; permanent managed identities |
| `deab224` | Log Analytics workspace and Application Insights |
| `0a251be` | Shared immutable package storage |
| `ff29a5b` | Permanent public IP address for the NAT Gateway |
| `2620efa` | Certificate vault, admin vault, Key Vault provider settings, and role assignments |
| `618458f` | Self-signed WAF certificate |

## Next step

Proposed: remaining development foundation resources (pipeline identities with workload identity federation and Azure DevOps service connections, the Entra ID app registration, custom lock roles, Azure Policy, budgets, PIM (Privileged Identity Management) and Conditional Access). They start after Peter assigns them.