# Working agreement and project status

## How we work

- Peter assigns tasks to Codex and Claude. A task assigned to one assistant is not authorization for the other to perform it.
- Explain work to Peter in Slovak, in small steps. Keep repository and website content in English. Expand abbreviations in parentheses.
- During guided learning, Peter edits files and runs commands in Visual Studio Code himself. Codex explains and reviews in this chat; do not hand work to an editor assistant. Codex may make a directly requested change within the assigned scope.
- Before changing files or running commands that change state, show the exact location, proposed content or command, and its purpose. Wait for Peter's explicit instruction to proceed. Confirmation of understanding is not approval to make changes.
- An explicit instruction to perform a reviewed change authorizes that scope; do not repeatedly request the same approval. Stop and explain any material change in scope.
- After each approved block, show the result and checks, then pause for Peter. Do not independently start the next implementation step.
- Use the architectural reference selected by Peter. Keep private source documents, their contents, credentials, and real environment configuration outside this public repository. If required private context is unavailable, ask Peter rather than inventing requirements.

## Coordination through GitHub

- Before an assigned task, read the latest version of this file, the relevant build log, recent commits, and local changes. Preserve uncommitted work when synchronizing with GitHub.
- Record the task owner and affected files for approved work. Do not edit files another contributor is actively changing; coordinate through Peter first.
- GitHub records published changes. It does not automatically share conversations, local work, or task ownership, and this file is not a technical lock.
- After approved work, record what changed, the affected files, checks and their results, the commit reference when available, remaining work, and the next proposed step. Distinguish planned, reported, and verified outcomes.
- Keep detailed step records under `docs/build-log/`. Update this file only with working agreements and concise coordination status.

## Repository work completed

| Change | Contributor | Evidence |
| --- | --- | --- |
| Created the public repository with an English design summary and version-control exclusions | Codex | [Initial commit](https://github.com/PeterHudcovic/azure-appservice-platform-lab/commit/d8c2d295978d87c38f5a782b92016f09bfdc2cd8) |
| Added the documented environment and layer directory structure, preserving intervening repository changes | Codex | [Directory structure commit](https://github.com/PeterHudcovic/azure-appservice-platform-lab/commit/acccac095c45b7e262af64e424251b63dd07ecb9) |
| Added the collaboration agreement and the first Preparation record | Codex | [Coordination commit](https://github.com/PeterHudcovic/azure-appservice-platform-lab/commit/9ce26b6f15587aaec88055e40e14fa7579164415) |
| Completed the Preparation record with detailed results, lessons, and open items | Claude | Commit history of `docs/build-log/01-preparation.md` |
| Created the initial development foundation Terraform configuration | Peter, guided by Codex | Commit `a982397`; [configuration record](docs/build-log/02-terraform-configuration.md) |
| Added the configuration build record | Peter, with assistant support | Commit `444c8e9` |
| Synchronized the project overview, development foundation description, and coordination status with the initial configuration | Codex, on Peter's request | `README.md`, `infra/environments/development/layer-0-foundation/README.md`, and this file |
| Added the development state storage, one state container per layer, a layer 0 data role, and the remote backend; migrated layer 0 state to Azure | Peter, guided by Claude | Commit `4c7b647`; [state bootstrap record](docs/build-log/03-development-state-bootstrap.md) |
| Added the state bootstrap record and synchronized coordination status | Peter, guided by Claude | `docs/build-log/03-development-state-bootstrap.md`, `infra/environments/development/layer-0-foundation/README.md`, and this file |
| Added development foundation resources: resource groups, permanent managed identities, monitoring, shared package storage, NAT address, certificate and admin vaults, and the WAF certificate | Peter, guided by Claude | Commits `d14806b` to `618458f`; [foundation resources record](docs/build-log/04-development-foundation-resources.md) |
| Added development pipeline identities, their roles, federated credentials, and five Azure DevOps service connections without secrets | Peter, guided by Claude | Commits `48b7ff0` to `69b78e8`; [pipeline identities record](docs/build-log/05-development-pipeline-identities.md) |
| Added the Entra ID app registration for user sign-in, the non-production budget, and Azure Policy assignments with exemptions | Peter, guided by Claude | Commits `2b5fdf3` to `c2787ca`; [governance record](docs/build-log/06-development-sign-in-and-governance.md) |
| Built development layer 1: virtual network, subnets, network security, NAT Gateway, private DNS, vault private endpoints, Ops VM with Bastion Developer, VNet flow log, and Managed DevOps Pools; added flow log storage and agent network roles to layer 0 | Peter, guided by Claude | Commits `5a0638e` to `c83884a`; [network and operations record](docs/build-log/07-development-network-operations.md) |

The `infra/environments/` directory contains `development/`, `testing/`, and `production/`. Each has `layer-0-foundation/`, `layer-1-network-operations/`, and `layer-2-application/`. The development foundation and development network and operations layers contain Terraform configuration; the other layer directories contain documentation only. The `infra/modules/` directory is reserved for reusable infrastructure code and currently contains documentation only. The folder structure does not establish infrastructure isolation or replace the approved architectural reference.

The development foundation layer defines the Terraform state storage account and remote backend, resource groups for all layers, permanent managed identities, monitoring, shared package storage, a static NAT address, the certificate and admin vaults, the WAF certificate, pipeline identities federated with five Azure DevOps service connections, the Entra ID app registration with its user group, a budget, Azure Policy for the non-production subscription, flow log storage, network roles for Managed DevOps Pools, and a temporary layer 1 state role (`temporary.tf`, removed when the pipeline takes over layer 1). Its state is stored in Azure.

The development network and operations layer defines the virtual network with six subnets, network security groups and application security groups, the NAT Gateway, private DNS zones, private endpoints for the certificate and admin vaults, the Ops VM with Bastion Developer, a VNet flow log with Traffic Analytics, and two Managed DevOps Pools. It was built locally by Lab Admin; its state is stored in Azure. Custom lock roles, PIM, and Conditional Access (planned with production), reusable module implementations, the testing and production environments, and automation pipelines are not present. Preparation performed manually by Peter is recorded separately in the build log.

## Current coordination

| Participant | Current responsibility or reported status |
| --- | --- |
| Peter | Edits configuration and runs commands during guided learning, assigns tasks, and approves changes |
| Claude | Leads the development foundation and development network and operations Terraform work on Peter's assignment; explains and reviews, while Peter edits files and runs commands |
| Codex | Not assigned to the development layers during Claude's assignment; may review on Peter's request |

Current step record: [07 - Development Network and Operations](docs/build-log/07-development-network-operations.md). Earlier records: [01 - Preparation](docs/build-log/01-preparation.md), [02 - Terraform Configuration](docs/build-log/02-terraform-configuration.md), [03 - Development State Bootstrap](docs/build-log/03-development-state-bootstrap.md), [04 - Development Foundation Resources](docs/build-log/04-development-foundation-resources.md), [05 - Development Pipeline Identities](docs/build-log/05-development-pipeline-identities.md), and [06 - Development Sign-in and Governance](docs/build-log/06-development-sign-in-and-governance.md).

Next proposed step: development layer 2 (application). Layer 1 runs locally until its pipeline exists; then `temporary.tf` is removed.

Claude is assigned to the development foundation and network and operations layers. Entries describe the latest recorded handoff, not live activity; confirm ownership before starting overlapping work.
