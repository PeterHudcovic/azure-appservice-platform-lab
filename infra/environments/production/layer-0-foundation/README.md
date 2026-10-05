# Production - Layer 0: Foundation

**Scope:** Persistent foundation resources for the production environment in the separate production subscription, including production access control.

**Lifecycle:** This layer remains in place when layers 2 and 1 are removed. It is never destroyed as part of the normal workflow. The vaults have purge protection.

**Status: Built.** All resources exist and `terraform plan` reports no changes. The state is stored in `stsitstfprodswc`, container `tfstate-layer0`. Build records: [11](../../../../docs/build-log/11-production-environment.md) and [12](../../../../docs/build-log/12-monitoring-alerts-and-infrastructure-pipelines.md).

## Contents

| File | Resources |
| --- | --- |
| `main.tf` | State storage (one container per layer), resource groups of all layers, permanent application and gateway identities, own Log Analytics and Application Insights, NAT public address, certificate and admin vaults with purge protection, self-signed WAF certificate, pipeline identities with federated credentials and resource group roles, package read role for the deploy identity (shared package storage in the non-production subscription), Entra ID app registration and user group for sign-in, production budget |
| `policy.tf` | Azure Policy assignments for the production subscription and exemptions for the certificate and admin vaults |
| `access.tf` | Production administrator: permanent Reader and Virtual Machine User Login, PIM (Privileged Identity Management) eligible roles with activation rules, custom lock roles for the layer 2 and destroy identities |
| `conditional-access.tf` | Named location and two report-only Conditional Access policies for the production administrator (Lab Admin excluded) |
| `network-watcher.tf` | `NetworkWatcherRG` and the regional Network Watcher in the allowed region |
| `flowlogs.tf` | Storage account for VNet flow logs |
| `managed-devops-pools.tf` | Network roles of the DevOpsInfrastructure service on the network resource group |
| `application-access.tf` | Key Vault Secrets User for the application identity and Website Contributor for the deploy identity |
| `pipeline-access.tf` | Roles of the infrastructure and destroy pipeline identities outside their own resource groups |
| `temporary.tf` | Temporary state roles for Lab Admin on the layer 1 and 2 state containers (removal waits for Peter's decision) |

## Usage

Layer 0 is applied by an administrator, not by a pipeline. It changes Entra ID, PIM, and Conditional Access, so every apply needs Peter's approval. Sign in to Azure CLI (Command-Line Interface) with the Lab Admin account and check the signed-in account before each run.

1. Copy `production.example.tfvars` to `production.tfvars` and fill in the real values. The file is ignored by Git.
2. `terraform init`
3. `terraform plan -var-file="production.tfvars" -out="tfplan"`, review, then `terraform apply "tfplan"`.
4. A second plan must report no changes; then delete `tfplan`.
