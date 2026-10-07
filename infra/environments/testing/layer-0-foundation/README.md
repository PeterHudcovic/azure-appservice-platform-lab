# Testing - Layer 0: Foundation

**Scope:** Persistent foundation resources for the testing environment in the non-production subscription.

**Lifecycle:** This layer remains in place when layers 2 and 1 are removed. It is never destroyed as part of the normal workflow.

**Status: Built.** All resources exist and `terraform plan` reports no changes. The state is stored in `stsitstftestswc`, container `tfstate-layer0`. Build records: [10](../../../../docs/build-log/10-testing-environment.md) and [12](../../../../docs/build-log/12-monitoring-alerts-and-infrastructure-pipelines.md).

Testing shares with development: the Log Analytics workspace and Application Insights, the package storage, and the subscription-level Azure Policy assignments and budget, which are all managed in the development foundation layer.

## Contents

| File | Resources |
| --- | --- |
| `main.tf` | State storage (one container per layer), resource groups of all layers, permanent application and gateway identities, NAT public address, certificate and admin vaults, self-signed WAF certificate, pipeline identities with federated credentials and resource group roles, package read role for the deploy identity, Entra ID app registration and user group for sign-in |
| `policy.tf` | Policy exemption for the certificate and admin vaults, scoped to the foundation resource group |
| `flowlogs.tf` | Storage account for VNet flow logs |
| `managed-devops-pools.tf` | Network roles of the DevOpsInfrastructure service on the network resource group |
| `application-access.tf` | Key Vault Secrets User for the application identity and Website Contributor for the deploy identity |
| `pipeline-access.tf` | Roles of the infrastructure and destroy pipeline identities outside their own resource groups, including the shared monitoring |
| `temporary.tf` | Temporary state roles for Lab Admin on the layer 1 and 2 state containers (removal waits for Peter's decision) |

## Usage

Layer 0 is applied by an administrator, not by a pipeline. Sign in to Azure CLI (Command-Line Interface) with the Lab Admin account and check the signed-in account before each run.

1. Copy `testing.example.tfvars` to `testing.tfvars` and fill in the real values. The file is ignored by Git.
2. `terraform init`
3. `terraform plan -var-file="testing.tfvars" -out="tfplan"`, review, then `terraform apply "tfplan"`.
4. A second plan must report no changes; then delete `tfplan`.
