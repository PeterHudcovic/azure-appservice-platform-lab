# Development - Layer 0: Foundation

**Scope:** Persistent foundation resources for the development environment in the non-production subscription, plus resources shared by the non-production environments.

**Lifecycle:** This layer remains in place when layers 2 and 1 are removed. It is never destroyed as part of the normal workflow.

**Status: Built.** All resources exist and `terraform plan` reports no changes. The state is stored in the blob `development-layer0.tfstate` in the container `tfstate-layer0` of `stsitstfdevswc`. Build records: [03](../../../../docs/build-log/03-development-state-bootstrap.md) to [07](../../../../docs/build-log/07-development-network-operations.md), [08](../../../../docs/build-log/08-development-application.md), and [12](../../../../docs/build-log/12-monitoring-alerts-and-infrastructure-pipelines.md).

## Contents

| File | Resources |
| --- | --- |
| `main.tf` | State storage (one container per layer), resource groups of all layers, permanent application and gateway identities, Log Analytics and Application Insights (shared by testing), shared package storage with immutability (all environments), NAT public address, certificate and admin vaults, self-signed WAF certificate, pipeline identities with federated credentials and resource group roles, Entra ID app registration and user group for sign-in, non-production budget |
| `policy.tf` | Azure Policy assignments for the non-production subscription (tags, allowed region, HTTPS and TLS for web apps, no public Key Vault access) and exemptions |
| `flowlogs.tf` | Storage account for VNet flow logs |
| `managed-devops-pools.tf` | Network roles of the DevOpsInfrastructure service on the network resource group |
| `application-vault-access.tf` | Key Vault Secrets User for the application identity on the Key Vault resource group |
| `application-deploy-access.tf` | Website Contributor for the deploy pipeline identity on the application resource group |
| `pipeline-access.tf` | Roles of the infrastructure and destroy pipeline identities outside their own resource groups |
| `temporary.tf` | Temporary state roles for Lab Admin on the layer 1 and 2 state containers (removal waits for Peter's decision) |

## Usage

Layer 0 is applied by an administrator, not by a pipeline. Sign in to Azure CLI (Command-Line Interface) with the Lab Admin account and check the signed-in account before each run.

1. Copy `development.example.tfvars` to `development.tfvars` and fill in the real values. The file is ignored by Git.
2. `terraform init`
3. `terraform plan -var-file="development.tfvars" -out="tfplan"`, review, then `terraform apply "tfplan"`.
4. A second plan must report no changes; then delete `tfplan`.
