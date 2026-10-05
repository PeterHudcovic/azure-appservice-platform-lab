# 12 - Monitoring Alerts and Infrastructure Pipelines

**Status:** Alerts are in place in all three environments. The development and testing infrastructure pipelines run layers 1 and 2 from Azure DevOps and end with No changes. The production infrastructure pipelines exist with a plan stage and an approval stage; the production layer 0 roles they need are planned but not yet applied (the production apply waits for Peter), so no production infrastructure pipeline has run yet.

**Execution:** Claude wrote the configuration and ran the local steps with the Lab Admin account on the branch `claude/dev-layer2`. Pipeline definitions, permissions, and runs were created through the Azure DevOps REST API. Peter decided that the sign-in application client ID is passed as a variable instead of being looked up through Microsoft Graph.

## Monitoring alerts (`layer-2-application/alerts.tf` in each environment)

| Alert | Type | Condition | Severity |
| --- | --- | --- | --- |
| `alert-sits-<env>-app-unhealthy` | Metric | Web App `HealthCheckStatus` average below 100 over 5 minutes | 1 |
| `alert-sits-<env>-gateway-backend-unhealthy` | Metric | Gateway `UnhealthyHostCount` average above 0 over 5 minutes | 1 |
| `alert-sits-<env>-keyvault-access-denied` | Log query | `AzureDiagnostics` of the application vault, HTTP status 403, count above 0 in 5 minutes | 2 |
| `alert-sits-<env>-waf-request-matched` | Log query | `ApplicationGatewayFirewallLog` of the gateway, action Blocked, Detected, or Matched, count above 0 in 5 minutes | 3 |

Every alert notifies the action group `ag-sits-<env>-swc` by e-mail. The recipient is the variable `alert_email` (local variables file and pipeline variable, not in the repository). Testing uses the shared non-production workspace, production its own.

## Infrastructure pipelines

| Pipeline | File | Agent | Environment |
| --- | --- | --- | --- |
| `sits-infra-dev-l1` | `pipelines/infra-dev-l1.yml` | Microsoft-hosted | `dev` |
| `sits-infra-dev-l2` | `pipelines/infra-dev-l2.yml` | `mdp-sits-dev-infra-swc` | `dev` |
| `sits-infra-test-l1` | `pipelines/infra-test-l1.yml` | Microsoft-hosted | `test` |
| `sits-infra-test-l2` | `pipelines/infra-test-l2.yml` | `mdp-sits-test-infra-swc` | `test` |
| `sits-infra-prod-l1` | `pipelines/infra-prod-l1.yml` | Microsoft-hosted | plan stage, then `prod-infra` (approval) |
| `sits-infra-prod-l2` | `pipelines/infra-prod-l2.yml` | `mdp-sits-prod-infra-swc` | plan stage, then `prod-infra` (approval) |

Layer 1 runs on a Microsoft-hosted agent because it creates the private agent pools. The shared steps (`pipelines/templates/terraform-steps.yml`):

1. Check that the service connection points to the expected subscription; otherwise stop before any change.
2. Sign in with workload identity federation (OIDC), no secrets.
3. Plan with `-detailed-exitcode`. With `planOnly` (production stage 1) stop here.
4. Apply only when the plan shows changes.
5. Plan again; the run fails unless this verification plan shows No changes.

Production: stage 1 shows the plan and changes nothing; stage 2 is a deployment job on the `prod-infra` environment with a mandatory approval by Peter; it plans again, applies, and verifies. The second plan is not the reviewed plan file (a plan file would contain the generated Ops VM password and must not become a pipeline artifact); the approver compares the plan of stage 1 with the log of stage 2.

## Changes needed for the pipelines

| Change | Files | Reason |
| --- | --- | --- |
| Roles for the infra-l1, infra-l2, and destroy identities outside their own resource groups | `layer-0-foundation/pipeline-access.tf` (development, testing, production) | Layers 1 and 2 read layer 0 resources and use them (see below) |
| Sign-in client ID as variable `app_client_id`; `data.azuread_application` and the azuread provider removed from layer 2 | `layer-2-application/main.tf`, `appservice.tf`, `variables.tf`, `versions.tf`, `providers.tf`, example variables files | Pipeline identities need no Microsoft Graph permission (Peter's decision) |
| `trimsuffix(var.azure_devops_organization_url, "/")` | `layer-1-network-operations/managed-devops-pools.tf` | `$(System.CollectionUri)` ends with a slash, which the provider rejects |
| Pipeline variables `alertEmail` and `appClientId` | Azure DevOps definitions of the layer 2 pipelines | Values stay out of the repository |

### Pipeline identity roles added in layer 0

| Identity | Role | Scope | Reason |
| --- | --- | --- | --- |
| infra-l1, infra-l2, destroy | Reader | foundation resource group | Look up layer 0 resources by name |
| infra-l1, destroy | Network Contributor | `NetworkWatcherRG` | The VNet flow log is a child of the Network Watcher |
| infra-l1 | Storage Account Contributor | flow log storage account | Network Watcher writes with the account key |
| infra-l1 | Log Analytics Contributor | workspace | Traffic Analytics links to the workspace |
| infra-l1 | Key Vault Contributor | certificate and admin vaults | Automatic approval of the private endpoints |
| infra-l2 | Network Contributor | network resource group | Join subnets and security groups, internal DNS record |
| infra-l2 | Managed Identity Operator | application and gateway identities | Attach the permanent identities |
| infra-l2 | Log Analytics Contributor | workspace | Diagnostic settings and log alerts |
| testing only: infra-l2, destroy | Reader | shared Application Insights (development) | Connection string of the shared monitoring |
| testing only: destroy | Reader | shared workspace (development) | Refresh before destroy |

No identity can assign roles. Known limits (also noted in build log 13): `NetworkWatcherRG` is shared by development and testing in the non-production subscription; Storage Account Contributor includes account key access; Network Contributor covers the whole network resource group. A company would use narrower custom roles.

## Azure DevOps

| Item | Value |
| --- | --- |
| New pipeline definitions | `sits-infra-test-l1`, `sits-infra-test-l2`, `sits-infra-prod-l1`, `sits-infra-prod-l2` (folder `\sits`) |
| New environment | `prod-infra` with a mandatory approval by Peter (same approver as `prod-app`) |
| Authorizations | Development and testing: each service connection is authorized only for its own pipeline; the environments `dev` and `test` and the infrastructure pools for the infrastructure pipelines. Production: left for Peter to authorize on the first run |

## Checks

| Check | Result |
| --- | --- |
| Development alerts | 5 added; second plan No changes; Azure lists 2 metric alerts, 2 log alerts, and the action group, all enabled |
| Testing and production alerts | 5 added each; second plan No changes |
| Development layer 0 roles | 13 added; second plan No changes |
| Testing layer 0 roles | 16 added; second plan No changes |
| Production layer 0 roles | Plan: 13 to add, 0 to change, 0 to destroy. Not applied: the production apply was not permitted for the assistant and waits for Peter |
| Layer 2 without Microsoft Graph lookup | Development, testing, and production plans: No changes. Development and testing state refreshed (refresh-only, no Azure change); production state still lists the old lookup, which is harmless |
| `sits-infra-dev-l1` run 7 | Failed at plan: organization URL with trailing slash; nothing changed (refresh succeeded, so the roles were sufficient) |
| `sits-infra-dev-l1` run 9 | Plan No changes, apply skipped, verification plan No changes |
| `sits-infra-dev-l2` run 8 | Plan No changes, apply skipped, verification plan No changes |
| `sits-infra-test-l1` run 10 | Plan No changes, apply skipped, verification plan No changes |
| `sits-infra-test-l2` run 11 | Plan No changes, apply skipped, verification plan No changes |
| Read-only acceptance (started) | Web Apps: public access disabled, HTTPS only (all three). Application vaults: public access disabled, default action Deny, RBAC (production with purge protection). Network peering: none in any environment. Gateway backends: Healthy (all three). Production locks: CanNotDelete on the application and application vault resource groups. Conditional Access: both policies report-only |

## Remaining work

1. Peter applies production layer 0 (`pipeline-access.tf`, 13 roles), then a second plan must show No changes.
2. First runs of `sits-infra-prod-l1` and `sits-infra-prod-l2`: Peter authorizes the service connections, the production infrastructure pool, and `prod-infra`, reads the plan, and approves. Both must end with No changes.
3. After the pipelines take over layers 1 and 2: remove `temporary.tf` in each layer 0 (the temporary Lab Admin state roles).
4. Destroy pipeline: the destroy identities have the new read roles, `destroy-dev.yml` passes the new variables, and the `sits-destroy-dev` definition has the variables `alertEmail` and `appClientId`. Its authorizations (service connection `dev-destroy`, environment `dev-destroy`, infrastructure pool) are given on its first run; it has never run.
5. Rebuilding layer 1 from a pipeline may need the pipeline identity to be allowed to register Managed DevOps Pools in Azure DevOps; not tested, because every run reported No changes.
