# 01 - Preparation

**Status:** Completed, except two postponed items (see Open items).

**Execution:** Peter performed all steps manually, in the Azure portal, the Microsoft 365 admin center, Azure DevOps, and with CLI (Command-Line Interface) commands, with guidance from Claude. Nothing in this step was created with Terraform. Claude has no direct access to Peter's Azure environment. Each result below was confirmed by Peter with a portal screenshot or CLI output during the session. Codex has not independently inspected Azure for this step.

## Completed

| Area | Result |
| --- | --- |
| Tenant | Dedicated Microsoft Entra ID tenant for the lab |
| Subscriptions | One non-production subscription (Development and Testing) and one production subscription (Pay-As-You-Go). The non-production subscription was renamed from its default name to match the naming convention. |
| Licensing | Microsoft Entra ID P2 trial, needed for PIM (Privileged Identity Management) and Conditional Access. Recurring billing is turned off. |
| Lab Admin account | Work account in the lab tenant. Global Administrator, Owner on both subscriptions, P2 license, MFA (Multi-Factor Authentication) with Microsoft Authenticator and a passkey. |
| Prod Admin account | Separate work account for production work. P2 license, MFA with Microsoft Authenticator. No Azure roles assigned yet. |
| Azure DevOps | Organization and private project created. Free parallel jobs: 1 Microsoft-hosted, 1 self-hosted. |
| Azure features | `EnableApplicationGatewayNetworkIsolation` registered in both subscriptions. `Microsoft.Network` resource provider registered. |

Tenant and subscription identifiers, account names, credentials, and network addresses are intentionally excluded from this public record.

## Lessons learned

- A personal Microsoft account (for example Gmail) cannot use the Microsoft 365 admin center. A work account in the tenant is required.
- A license cannot be assigned until the user has a usage location.
- Azure DevOps lists a subscription for a service connection only if the signed-in account has rights on it. Always sign in to Azure DevOps with the Lab Admin account, not the personal account.
- A new subscription may not appear in the portal subscription filter immediately. `az account list --refresh` shows it.

## Open items

- Test users, postponed by Peter: `app-user` (allowed to sign in) and `app-denied` (must receive error AADSTS50105). Both need a usage location and a P2 license.
- Prod Admin role assignments (Reader on production, VM login, PIM eligibility): planned for Terraform layer 0 and PIM.

## Repository work

- Codex created the public repository, `README.md`, and `.gitignore` in [commit d8c2d29](https://github.com/PeterHudcovic/azure-appservice-platform-lab/commit/d8c2d295978d87c38f5a782b92016f09bfdc2cd8).
- Codex added the directory structure under `infra/environments/` and `infra/modules/` in [commit acccac0](https://github.com/PeterHudcovic/azure-appservice-platform-lab/commit/acccac095c45b7e262af64e424251b63dd07ecb9).
- Codex added `AGENTS.md` and the first version of this record in [commit 9ce26b6](https://github.com/PeterHudcovic/azure-appservice-platform-lab/commit/9ce26b6f15587aaec88055e40e14fa7579164415).
- Claude completed this record with the detailed preparation results.

## What this record does not establish

No infrastructure is deployed yet. This step prepares accounts, licenses, subscriptions, and services. It does not demonstrate a working platform or environment isolation.

## Next step

Not assigned. Step 2 (Terraform modules) starts only after Peter assigns it.

Collaboration rules and the concise current status are maintained in [AGENTS.md](../../AGENTS.md).
