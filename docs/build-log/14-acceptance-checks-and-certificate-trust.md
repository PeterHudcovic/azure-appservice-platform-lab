# 14 - Acceptance Checks and Certificate Trust

**Status:** Completed. Read-only acceptance checks pass in all three environments, with the deviations and limits listed below. The Ops VMs of all three environments trust their environment's WAF certificate, and HTTPS to the application through the gateway validates without a warning.

**Execution:** Claude ran the checks with the Lab Admin account through Azure CLI on 2026-10-05 and 2026-10-06. The only state change was the certificate import on the three Ops VMs (Azure VM run command). No Terraform configuration changed.

## Acceptance checks (read-only)

| Area | Check | Development | Testing | Production |
| --- | --- | --- | --- | --- |
| Web App | Public network access | Disabled | Disabled | Disabled |
| Web App | HTTPS only, minimum TLS 1.2, FTPS disabled, health path `/health`, all outbound through the virtual network | Yes | Yes | Yes |
| Application vault | Public access disabled, default action Deny, RBAC authorization | Yes | Yes | Yes, plus purge protection |
| Network | Virtual network peerings | None | None | None |
| Network | Every network security group ends with a Deny rule at priority 4000 | 6 of 6 | 6 of 6 | 7 of 7 |
| Network | Application name from another environment's Ops VM | `app.test` not resolvable from development | `app.prod` not resolvable from testing | `app.prod` not resolvable from development (Peter, build log 11) |
| Gateway | WAF policy | Enabled, Detection, Microsoft_DefaultRuleSet 2.1 | Same | Same |
| Gateway | Backend health | Healthy | Healthy | Healthy |
| Storage | State and package accounts: shared key disabled, no public blob access, TLS 1.2 | Yes | Yes | Yes |
| Storage | Flow log accounts | Shared key enabled (conscious, build log 07) | Same | Same |
| Monitoring | Metric and log alerts enabled | Yes | Yes | Yes |
| Governance | Delete locks | Not designed | Not designed | CanNotDelete on the application and application vault resource groups |
| Governance | `admin-prod` active roles | | | Reader (subscription), Virtual Machine User Login (network resource group) only |
| Governance | `admin-prod` PIM (Privileged Identity Management) eligible roles | | | Contributor (subscription), Key Vault Secrets Officer (application vault resource group), Key Vault Secrets User (admin vault) |
| Governance | Conditional Access | | | Both policies report-only |
| Sign-in | Members of the application user group (added by Peter) | Lab Admin | Lab Admin | Lab Admin |
| Governance | Azure Policy | Non-production: the custom location, Key Vault, and Web App policies show 0 non-compliant resources | Same subscription as development | Assignments present; no compliance results yet (first evaluation pending) |
| Delivery | Infrastructure pipelines end with No changes | Runs 8, 9 | Runs 10, 11 | Runs 12, 13 (approved) |

The non-production tag policies report 5 non-compliant resources each. All of them are created by Azure, not by Terraform: the Traffic Analytics data collection endpoint and rule, the automatic Network Watchers in `NetworkWatcherRG`, and the Application Insights smart detection action group. The default Microsoft Defender for Cloud initiative (`securitycenterbuiltin`) reports 16 recommendations; it is outside the design scope.

## Ops VM trust of the WAF certificate

The WAF certificates are self-signed in the certificate vaults (lab limitation; a company would use its own certificate authority). Until now the Ops VM browsers showed "Not secure".

1. The public part of each certificate was downloaded from its certificate vault (`az keyvault certificate download --encoding PEM`). The private key never left the vault.
2. A short PowerShell script imported it into `Cert:\LocalMachine\Root` on the Ops VM of the same environment (`az vm run-command invoke --command-id RunPowerShellScript`).
3. A second run command requested `https://app.<env>.sits.internal/health` from each Ops VM.

| Environment | Certificate subject | Thumbprint | Valid until | HTTPS check from the Ops VM |
| --- | --- | --- | --- | --- |
| Development | `CN=app.dev.sits.internal` | `AC0C2D04...3A92` | 2027-10-04 | Trusted, HTTP 200 |
| Testing | `CN=app.test.sits.internal` | `C018A5FE...5A5C` | 2027-10-05 | Trusted, HTTP 200 |
| Production | `CN=app.prod.sits.internal` | `0D854E3D...73FE` | 2027-10-05 | Trusted, HTTP 200 |

Limits: the import is an operational step outside Terraform. It must be repeated when the certificate is renewed (Key Vault policy: 12 months) or when layer 1 recreates an Ops VM. Each Ops VM trusts only its own environment's certificate.

## Production administrator sign-in (test by Peter)

| Check | Result (reported by Peter) |
| --- | --- |
| `admin-prod` signs in to `vm-sits-prod-ops-swc` through Bastion Basic with Microsoft Entra ID authentication | Succeeded with MFA (multifactor authentication) using a passkey |
| Identity on the Ops VM (`whoami`) | `azuread\prodadmin`: an Entra ID account, not the local emergency account `opsadmin` |
| What `admin-prod` sees in the Azure portal | Only the production VM; no non-production resources |

This confirms the production access design: `admin-prod` signs in to the Ops VM through its permanent Virtual Machine User Login role and the `AADLoginForWindows` extension, and its permanent Reader role covers only the production subscription. Its PIM eligible roles were not activated for this test. No Azure configuration was changed for this record.

## Remaining work

1. Remove `temporary.tf` in each layer 0 (Lab Admin state roles for layers 1 and 2); waits for Peter's decision because it removes Lab Admin role assignments.
2. Conditional Access stays report-only until Peter switches it on.
