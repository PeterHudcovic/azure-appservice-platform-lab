# 10 - Testing Environment

**Status:** Completed. Testing layers 0, 1, and 2 are built in the shared non-production subscription, match the configuration (`terraform plan` reports no changes), and the same package as development runs and passes its health and sign-in checks.

**Execution:** Claude wrote the configuration and ran it locally with the Lab Admin account on the branch `claude/dev-layer2`. Peter approved the layer 0 apply (it includes Entra ID changes) and authorized the Azure DevOps resources. Following Peter's decision to save time, the testing layers are copies of the development layers with testing values; the refactor into `infra/modules` is a planned next step.

## Differences from development

| Item | Development | Testing |
| --- | --- | --- |
| Address space | 10.10.0.0/16 | 10.20.0.0/16 |
| App Service plan | B1, one instance | P0v3, autoscale 1 to 3 (CPU above 70 percent scales out, below 30 percent scales in) |
| Gateway address | 10.10.4.10 | 10.20.4.10 |
| Managed DevOps Pools size | `Standard_D2ads_v5` | `Standard_D2as_v5` (see Issues) |
| Monitoring | Own workspace and Application Insights in layer 0 | Shares the non-production workspace and Application Insights of development (design: only production has its own) |
| Shared resources | Package storage, build identity, budget, and policy assignments | Not duplicated; testing layer 0 adds only exemptions and its own roles |
| State | `stsitstfdevswc` | `stsitstftestswc`, containers `tfstate-layer0`, `tfstate-layer1`, `tfstate-layer2` |

## Layer 0 (55 resources)

Resource groups for the foundation, network, application, and Key Vault; state storage with one container per layer; application and gateway identities; four pipeline identities (`infra-l1`, `infra-l2`, `deploy`, `destroy`) with their roles and federated credentials; NAT public IP; certificate and admin vaults with the WAF certificate for `app.test.sits.internal`; flow log storage; network roles for Managed DevOps Pools; Key Vault Secrets User for the application identity and Website Contributor for the deploy identity on their resource groups; temporary state roles for Lab Admin; Entra ID app registration `app-sits-test`, service principal with assignment required, federated credential to the application identity, and the group `grp-sits-test-app-users`.

The deploy identity reads the shared `packages` container (Storage Blob Data Reader).

The state was bootstrapped locally and migrated to `stsitstftestswc/tfstate-layer0/testing-layer0.tfstate`; the local copy is kept outside the repository.

## Layer 1 (71 resources) and layer 2 (15 resources)

Same resources as development layers 1 and 2, with the values above.

## Azure DevOps

| Item | Value |
| --- | --- |
| Service connections | `test-infra-l1`, `test-infra-l2`, `test-deploy`, `test-destroy`, created through the REST API with workload identity federation; federated credentials in testing layer 0 |
| Environment | `test` (no approval, design) |
| Pipeline | `sits-deploy-test` (`pipelines/deploy-test.yml`) on `mdp-sits-test-app-swc` |

## Checks

| Check | Result |
| --- | --- |
| Layer 0 plan | 46 to add first (5 Entra ID resources, approved by Peter); then 6, then 5, then 4 (federated credentials) |
| Layer 1 plan | 68 to add, then 3 after the pool size change |
| Layer 2 plan | 15 to add |
| Second `terraform plan` after each apply | No changes (layers 0, 1, 2) |
| Deploy run 5 (package `20261005.1`, the same as development) | Succeeded: SHA-256 verified, deployed through the private `.scm` endpoint, health check HTTP 200 with `"environment": "test"` and Key Vault access, anonymous request to `/` HTTP 401 |
| Gateway backend health | Healthy |

## Issues and fixes

- **Policy blocks the certificate and admin vaults.** The non-production Deny assignment `keyvault-no-public-access` blocked creating vaults with public access, and a resource-scoped exemption needs the vault to exist first. The exemption is scoped to `rg-sits-test-foundation-swc`, which holds only these two vaults (the application vault is in the Key Vault resource group without exemption). The exemption took about ten minutes to take effect.
- **Managed DevOps Pools quota.** The DADSv5 family has 5 vCPU per subscription and development uses 4, so the testing pools failed with `InsufficientCoreQuota`. The testing pools use the DASv5 family (`Standard_D2as_v5`).
- **Bastion Developer** failed once because the virtual network was still updating; a second apply succeeded.
- **Deploy run 4** failed the same way as the first development deployment (startup command before code, site start blocked, deployment tracking timed out). The deploy template now uses `--track-status false` and a longer health check, which verifies the real result.

## Conscious deviations

- Role placement on resource groups (design decisions 7 and 8), as in development.
- Policy exemption on the foundation resource group instead of on each vault.
- Layers copied instead of shared modules (time); modules refactor planned.

## Next step

Production environment.
