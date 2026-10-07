# Production - Layer 1: Network and Operations

**Scope:** The dedicated network and operational services of the production environment in the production subscription. There is no connection to the non-production networks.

**Lifecycle:** Created after layer 0 and before layer 2; removed after layer 2. The NAT public address, the flow log storage, and the Network Watcher live in layer 0 and survive a removal.

**Status: Built and run by its pipeline.** `sits-infra-prod-l1` (`pipelines/infra-prod-l1.yml`, identity `prod-infra-l1`, Microsoft-hosted agent) first shows the plan without changes, then waits for Peter's approval on the `prod-infra` environment, applies only when there are changes, and verifies that a second plan reports no changes. The state is stored in `stsitstfprodswc`, container `tfstate-layer1`. Build records: [11](../../../../docs/build-log/11-production-environment.md) and [12](../../../../docs/build-log/12-monitoring-alerts-and-infrastructure-pipelines.md).

## Contents

| File | Resources |
| --- | --- |
| `main.tf` | Virtual network 10.30.0.0/16 with seven subnets, including `AzureBastionSubnet` |
| `nsg.tf` | Network security group per subnet ending with Deny at priority 4000 (Bastion accepts HTTPS from the internet: conscious deviation, build record 11), application security groups |
| `nat.tf` | NAT Gateway with the permanent address from layer 0 |
| `dns.tf` | Private DNS zones for Key Vault, Web Apps, and `prod.sits.internal`, linked only to this network |
| `pe.tf` | Private endpoints to the certificate and admin vaults of layer 0 |
| `ops.tf` | Windows Ops VM with Microsoft Entra ID sign-in (system identity, `AADLoginForWindows`; the local account is for emergencies), Azure Bastion Basic with its public address |
| `flowlogs.tf` | VNet flow log with Traffic Analytics into the production workspace |
| `managed-devops-pools.tf` | Dev Center, project, and two stateless Managed DevOps Pools (infrastructure and application) |

## Usage

Normally run through `sits-infra-prod-l1` with Peter's approval. A local run with the Lab Admin account works while `temporary.tf` in layer 0 grants the state role, and also needs Peter's approval:

1. Copy `production.example.tfvars` to `production.tfvars` and fill in the real values. The file is ignored by Git.
2. `terraform init`
3. `terraform plan -var-file="production.tfvars" -out="tfplan"`, review, then `terraform apply "tfplan"`; a second plan must report no changes.
