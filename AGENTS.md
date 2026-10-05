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
| Built development layer 2 (application vault, App Service, Entra ID sign-in, Application Gateway WAF_v2, DNS record, diagnostics) and the layer 0 roles for the application and deploy identities | Claude, autonomously on Peter's assignment, applies approved by Peter | Branch `claude/dev-layer2`; [application record](docs/build-log/08-development-application.md) |
| Added the demo application and the Azure DevOps pipelines (build, development, testing and production deploy, layer 1 and 2 infrastructure, destroy) | Claude, autonomously on Peter's assignment | Branch `claude/dev-layer2`; [application and pipelines record](docs/build-log/09-application-and-pipelines.md) |
| Built the testing environment (layers 0, 1, 2) and its service connections | Claude, autonomously on Peter's assignment | Branch `claude/dev-layer2`; [testing record](docs/build-log/10-testing-environment.md) |
| Built the production environment (layers 0, 1, 2) with Bastion Basic, PIM, report-only Conditional Access, lock roles, and delete locks | Claude, autonomously on Peter's assignment, production and Entra ID applies approved by Peter | Branch `claude/dev-layer2`; [production record](docs/build-log/11-production-environment.md) |
| Added monitoring alerts, pipeline identity roles, and infrastructure pipelines for all three environments | Claude, on Peter's assignment; production layer 0 applied and production runs approved by Peter | Branch `claude/dev-layer2`; [alerts and pipelines record](docs/build-log/12-monitoring-alerts-and-infrastructure-pipelines.md) |
| Documented the access and permissions matrix | Codex, on Peter's assignment | [access matrix](docs/build-log/13-access-matrix.md) |
| Ran the acceptance checks and set up Ops VM trust of the WAF certificates | Claude, on Peter's assignment | Branch `claude/dev-layer2`; [acceptance record](docs/build-log/14-acceptance-checks-and-certificate-trust.md) |

The `infra/environments/` directory contains `development/`, `testing/`, and `production/`. Each has `layer-0-foundation/`, `layer-1-network-operations/`, and `layer-2-application/`, and every layer contains Terraform configuration with its own state in Azure. Testing and production are copies of the development layers with environment values; a refactor into `infra/modules/` is listed as a possible future improvement in the README. The `pipelines/` directory contains the Azure DevOps pipelines and their shared templates, and `app/` contains the demo application.

All nine layers were first built locally by Lab Admin with temporary state roles (`temporary.tf` in each foundation layer). Layers 1 and 2 of all three environments now run through the Azure DevOps infrastructure pipelines and end with No changes (production after Peter's approval); removing `temporary.tf` waits for Peter's decision. Monitoring alerts, acceptance checks, and Ops VM trust of the WAF certificates are complete. Conscious deviations from the design are recorded in build records 08, 10, 11, 12, and 14.

## Current coordination

| Participant | Current responsibility or reported status |
| --- | --- |
| Peter | Assigns tasks, approves production, Entra ID, and destroy actions, authorizes Azure DevOps resources, and learns from the build records |
| Claude | Builds all environments autonomously on Peter's assignment on the branch `claude/dev-layer2`; merge to `main` only with Peter's approval |
| Codex | Not assigned during Claude's assignment; may review on Peter's request |

Current step records: [12](docs/build-log/12-monitoring-alerts-and-infrastructure-pipelines.md), [13](docs/build-log/13-access-matrix.md) (Codex, access matrix at an earlier commit), and [14](docs/build-log/14-acceptance-checks-and-certificate-trust.md). Earlier records: [01](docs/build-log/01-preparation.md) to [11](docs/build-log/11-production-environment.md).

Next proposed steps: Peter's decision on removing `temporary.tf`, and the demonstration. Possible future improvements are listed under Next steps in the README.

Entries describe the latest recorded handoff, not live activity; confirm ownership before starting overlapping work.
