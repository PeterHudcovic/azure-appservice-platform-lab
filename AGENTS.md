# Working agreement and project status

## How we work

- Peter assigns tasks to Codex and Claude. A task assigned to one assistant is not authorization for the other to perform it.
- Explain work to Peter in Slovak, in small steps. Keep repository and website content in English. Expand abbreviations in parentheses.
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

The `infra/environments/` directory contains `development/`, `testing/`, and `production/`. Each has `layer-0-foundation/`, `layer-1-network-operations/`, and `layer-2-application/`. The `infra/modules/` directory is reserved for reusable infrastructure code. These directories currently contain explanatory README files only. The folder structure does not establish infrastructure isolation or replace the approved architectural reference.

Terraform implementation and automation pipelines are not present. Codex has not deployed Azure resources for this project. Preparation performed manually by Peter is recorded separately in the build log.

## Current coordination

| Participant | Current responsibility or reported status |
| --- | --- |
| Peter | Performs the manual Azure preparation steps, assigns tasks, and approves changes |
| Claude | Guides Preparation; reports no repository edits or unpublished local changes in the handoff supplied by Peter |
| Codex | Maintains the introductory repository documentation; awaits the next explicitly assigned implementation task |

Current step record: [01 - Preparation](docs/build-log/01-preparation.md).

No new infrastructure implementation task is assigned in this file. Entries describe the latest recorded handoff, not live activity; confirm ownership before starting overlapping work.
