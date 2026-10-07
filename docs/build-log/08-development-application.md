# 08 - Development Application

**Status:** Completed for the infrastructure. Development layer 2 (application) is built, matches the configuration (`terraform plan` reports no changes), and its security settings are verified. The test application is not deployed yet, so the WAF backend reports unhealthy.

**Execution:** Claude prepared the configuration on the branch `claude/dev-layer2` and ran the commands with the Lab Admin account after Peter approved each apply. Layer 2 was built locally from `infra/environments/development/layer-2-application/` with the temporary layer 2 state role (option B). The `dev-infra-l2` pipeline takes over this layer later.

## Layer 0 changes

| File | Resource | Purpose |
| --- | --- | --- |
| `temporary.tf` | Storage Blob Data Contributor for Lab Admin on `tfstate-layer2` | Temporary, for the local build. Removed when the `dev-infra-l2` pipeline takes over. |
| `application-vault-access.tf` | Key Vault Secrets User for `id-sits-dev-app-swc` on `rg-sits-dev-kv-swc` | The application identity reads secrets from the application vault |
| `application-deploy-access.tf` | Website Contributor for `id-sits-dev-deploy-swc` on `rg-sits-dev-app-swc` | The `dev-deploy` pipeline deploys packages to the Web App |

## Layer 2 resources

| Resource | Name | Configuration |
| --- | --- | --- |
| Key Vault | `kv-sits-dev-app-swc` | Standard, RBAC (role-based access control), public network access disabled, default action Deny, bypass None, soft-delete 7 days, purge protection off (development) |
| Private endpoint | `pe-kv-sits-dev-app-swc` | In `snet-pe`, member of `pe-kv-app`, record in `privatelink.vaultcore.azure.net` |
| App Service plan | `asp-sits-dev-swc` | Linux, B1, one instance |
| Web App | `app-sits-dev-swc` | Python 3.12, HTTPS only, TLS 1.2 also for `.scm`, FTP (File Transfer Protocol) and basic authentication disabled, public network access disabled, VNet integration in `snet-app` with all traffic routed, application identity from layer 0 for Key Vault references and `AZURE_CLIENT_ID`, health check `/health` |
| Sign-in | App Service Authentication | Entra ID with the `app-sits-dev` registration, sign-in required, `/health` excluded, `forward_proxy_convention = "Standard"`, no client secret (the registration trusts the application identity through a federated credential) |
| Private endpoint | `pe-app-sits-dev-swc` | In `snet-pe`, member of `pe-webapp`, record in `privatelink.azurewebsites.net` (application and `.scm`) |
| WAF policy | `waf-sits-dev-swc` | Microsoft_DefaultRuleSet 2.1, Detection mode |
| Application Gateway | `agw-sits-dev-swc` | WAF_v2, private address 10.10.4.10 only, autoscale 0 to 2, gateway identity from layer 0, HTTPS listener for `app.dev.sits.internal` with the versionless WAF certificate secret, TLS policy `AppGwSslPolicy20220101`, HTTPS backend to the Web App default host name with explicit host and SNI (Server Name Indication), probe `/health`, `X-Forwarded-Host` rewrite |
| DNS record | `app` in `dev.sits.internal` | Points to 10.10.4.10 |
| Diagnostic settings | `diag-log-sits-dev-swc` | Vault, Web App, and gateway (all logs and metrics), plan (metrics) to `log-sits-dev-swc` |

## Conscious deviations from the design

| Design | Implementation | Reason |
| --- | --- | --- |
| Implementation decisions 7 and 8: roles on permanent vaults are granted on the vault itself, and layer 2 recreates the application role on a recovered vault through a conditional role assignment administrator | Key Vault Secrets User for the application identity is granted in layer 0 on `rg-sits-dev-kv-swc` | The resource group holds only the application vault, so the effective scope is the same. The assignment survives a layer 2 destroy and a soft-delete recovery, and the layer 2 identity never assigns roles. |
| The deploy service connection has Website Contributor on the Web App only | Website Contributor for the deploy identity is granted in layer 0 on `rg-sits-dev-app-swc` | Same reasons. The group also holds the plan, gateway, and WAF policy; Website Contributor covers only web apps and plans. |

## Checks

| Check | Result |
| --- | --- |
| Layer 0 plan before apply | 2 to add, then 1 to add (deploy role); principals checked against the expected identities |
| Layer 2 plan before apply | 14 to add, 0 to change, 0 to destroy |
| Second `terraform plan` after each apply | No changes (layer 0 and layer 2) |
| `az storage blob list --auth-mode login` on `tfstate-layer2` | Access works through Entra ID (empty list, no error) |
| Application vault | Public access Disabled, default action Deny, bypass None, RBAC enabled |
| Web App | Public access Disabled, HTTPS only, all traffic routed through the VNet |
| Application Gateway backend health | Unhealthy with HTTP 404 from the backend: DNS, private endpoint, TLS, and certificate work; `/health` exists only after the test application is deployed |

## Issues and fixes

- The private design file was not at the expected path. The newest version was copied to the private folder outside the repository.
- In AzureRM 5.7, `azurerm_private_dns_a_record` takes `private_dns_zone_id` instead of the zone name and resource group. The provider schema was checked before writing the code.

## Decisions

- Private endpoints of layer 2 are placed next to their targets: the vault endpoint in `rg-sits-dev-kv-swc`, the Web App endpoint in `rg-sits-dev-app-swc`.
- Soft-delete retention of the application vault is 7 days, consistent with the layer 0 vaults (not stated in the design).
- The gateway reads the certificate through a versionless secret identifier built from the vault address, so Terraform never reads the certificate vault data plane.

## Open items

- Deploy the test application (`/` and `/health`) through the deploy pipeline on the application agent pool.
- Add a member to `grp-sits-dev-app-users`; without an assigned user, sign-in fails with AADSTS50105.
- Install the public part of the WAF certificate in the Ops VM trust store.
- Network roles for `dev-infra-l2` (subnet join, application security groups, private DNS zones) before the pipeline takes over layer 2.
- Sign-in without a client secret (federated credential on the application identity) is verified only after the application runs.

## Next step

Proposed: the test application and the Azure DevOps pipelines.
