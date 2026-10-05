# 11 - Production Environment

**Status:** Completed. Production layers 0, 1, and 2 are built in the separate Pay-As-You-Go production subscription and match the configuration (`terraform plan` reports no changes). The same package as development and testing was deployed after Peter's approval and passes its health and sign-in checks.

**Execution:** Claude wrote the configuration and ran it locally with the Lab Admin account on the branch `claude/dev-layer2`. Peter approved the layer 0 applies (they include Entra ID, PIM, and Conditional Access changes) and authorized the Azure DevOps resources. Long production applies ran as detached processes with logs outside the repository, after a window crash had interrupted one apply (see Incident).

## Production-specific design elements

| Element | Implementation |
| --- | --- |
| Separate subscription | `sub-app-prod`, own policy assignments, own budget (100, alerts only) |
| Own monitoring | `log-sits-prod-swc` and `appi-sits-prod-swc` |
| Address space | 10.30.0.0/16 with seven subnets, including `AzureBastionSubnet` (10.30.0.0/26) |
| Bastion | Basic in its own subnet with a public address and the NSG rules Bastion requires |
| Ops VM sign-in | Microsoft Entra ID: system identity and the `AADLoginForWindows` extension; the local account is for emergencies only; RDP only from `AzureBastionSubnet` |
| Production administrator | `admin-prod`: permanent Reader on the subscription and Virtual Machine User Login on the network resource group |
| PIM (Privileged Identity Management) | Eligible, not active: Contributor on the subscription, Key Vault Secrets User on the admin vault, Key Vault Secrets Officer on the application vault resource group; activation at most 2 hours, with justification and MFA |
| Conditional Access | Report-only (`enabledForReportingButNotEnforced`), Lab Admin always excluded: block the production administrator from the development and testing NAT addresses (named location); block device code sign-in for the production administrator. Peter switches them on manually. |
| Locks | Custom roles `SITS Lock Creator` (locks read and write, for `prod-infra-l2`) and `SITS Lock Remover` (locks read and delete, for `prod-destroy`); layer 2 creates `CanNotDelete` locks on the application and application vault resource groups |
| Purge protection | On for the certificate, admin, and application vaults |
| App Service plan | P0v3 with autoscale 1 to 3 |
| Gateway | WAF_v2, private address 10.30.4.10, Detection mode |
| Network Watcher | Managed in layer 0 (`NetworkWatcherRG`, `NetworkWatcher_swedencentral`) in the allowed region |

## Conscious deviations

| Design | Implementation | Reason |
| --- | --- | --- |
| Bastion accepts HTTPS only from the administrator address (`admin_ip`); certificate and admin vaults allow public access only from this address | Bastion accepts HTTPS from the internet; the certificate and admin vaults keep public access (with policy exemptions) as in development and testing | The administrator presents from an unknown mobile hotspot address. Access relies on Microsoft Entra ID sign-in with MFA, RBAC, and Conditional Access. A company would allow only its fixed corporate address. |
| Roles on the vault itself (decisions 7 and 8) | Key Vault Secrets User and Website Contributor on the resource groups in layer 0 | Same as development and testing |
| One agent subnet in production (six subnets) | Two agent subnets (infrastructure and application pools), seven subnets | Same pattern as development and testing (implementation decision 1: separate pools) |

## Azure DevOps

| Item | Value |
| --- | --- |
| Service connections | `prod-infra-l1`, `prod-infra-l2`, `prod-deploy`, `prod-destroy` (workload identity federation, created through the REST API); federated credentials in production layer 0 |
| Environment | `prod-app` with a mandatory approval |
| Pipeline | `sits-deploy-prod` (`pipelines/deploy-prod.yml`) on `mdp-sits-prod-app-swc`, manual start, same package and fingerprint check as testing |

## Checks

| Check | Result |
| --- | --- |
| Layer 0 | 73 planned; completed in several applies (see Incident); then 2 (Network Watcher) and 4 (federated credentials); second plan No changes |
| Layer 1 | 84 to add; second plan No changes |
| Layer 2 | 17 to add (including two locks); second plan No changes |
| Quotas | Dsv6 10 vCPU and Managed DevOps Pools DADSv5 5 vCPU in the production subscription |
| Deploy run 6 (`sits-deploy-prod`, package `20261005.1`, the same as development and testing) | Peter authorized the service connection, pool, and environment and approved the `prod-app` check; SHA-256 verified, deployed through the private `.scm` endpoint, health check HTTP 200 with `"environment": "prod"` and Key Vault access (after five 503 responses during the first start), anonymous request to `/` refused |
| Gateway backend health | Healthy |

## Incident and fixes

1. **Resource providers.** The new subscription had most resource providers unregistered, and azurerm 5.7 does not register them. The first apply created only 18 resources; providers were registered manually (Storage, ManagedIdentity, KeyVault, OperationalInsights, Insights, Web, Compute, AlertsManagement, DevCenter, DevOpsInfrastructure).
2. **Conditional Access named location.** `azuread_named_location.id` returns the Graph path; Conditional Access needs the object identifier (`object_id`).
3. **Window crash during apply.** The local state file was written empty while ten resources were being created. Recovery without changing Azure: the empty state, its backup, and the lock were saved outside the repository; the state was restored from the backup; a temporary `import.tf` recorded the ten existing resources; the plan showed 10 to import, 45 to add, 1 to change (the state storage blob settings that the interrupted apply had not finished), 0 to destroy. Later applies ran as detached processes.
4. **Transient policy exemption error** (`CheckAccessPrincipalTokenInvalid`): repeated a minute later.
5. **Network Watcher missing.** Created in layer 0 in the allowed region before the first virtual network.

## Next step

Monitoring alerts and acceptance checks.
