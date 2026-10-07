# Development - Layer 2: Application

**Scope:** The application platform of the development environment in the non-production subscription: the application Key Vault, the App Service plan and Linux Web App, their private endpoints, Entra ID sign-in, the Application Gateway with WAF (Web Application Firewall), the application DNS (Domain Name System) record, diagnostic settings, and alerts.

**Lifecycle:** Created after layer 1 and removed before layer 1. The application vault has a fixed name: a destroy leaves it in soft-delete, and the next apply recovers it with its secrets.

**Status: Built and run by its pipeline.** `sits-infra-dev-l2` (`pipelines/infra-dev-l2.yml`, identity `dev-infra-l2`, private pool `mdp-sits-dev-infra-swc`) plans, applies only when there are changes, and verifies that a second plan reports no changes. `sits-destroy-dev` can remove layers 2 and 1 for the demonstration. The state is stored in the blob `development-layer2.tfstate` in the container `tfstate-layer2`. Build records: [08](../../../../docs/build-log/08-development-application.md), [09](../../../../docs/build-log/09-application-and-pipelines.md), and [12](../../../../docs/build-log/12-monitoring-alerts-and-infrastructure-pipelines.md).

## Contents

| File | Resources |
| --- | --- |
| `main.tf` | Lookups of layer 0 and layer 1 resources by their fixed names, outputs |
| `keyvault.tf` | Application vault (private, RBAC (role-based access control), no trusted services bypass), private endpoint, application security group association |
| `appservice.tf` | App Service plan (B1), Linux Web App (Python 3.12, VNet integration with all outbound traffic, private endpoint, Entra ID sign-in without a client secret) |
| `gateway.tf` | WAF policy (Microsoft default rule set 2.1, Detection mode), Application Gateway WAF_v2 with a private address only, `app` record in `dev.sits.internal` |
| `diagnostics.tf` | Diagnostic settings of the vault, Web App, gateway, and plan to the development Log Analytics workspace |
| `alerts.tf` | Action group (e-mail) and alerts for application health, gateway backend health, denied Key Vault access, and WAF matches |

Layer 0 grants the application identity Key Vault Secrets User on the Key Vault resource group, so the layer 2 identity never assigns roles. No secrets are written by Terraform. The sign-in client ID is the variable `app_client_id`, so the pipeline identity needs no Microsoft Graph permission.

## Usage

Normally run through `sits-infra-dev-l2`; its definition holds the variables `alertEmail` and `appClientId`. A local run with the Lab Admin account works while `temporary.tf` in layer 0 grants the state role:

1. Copy `development.example.tfvars` to `development.tfvars` and fill in the real values. The file is ignored by Git.
2. `terraform init`
3. `terraform plan -var-file="development.tfvars" -out="tfplan"`, review, then `terraform apply "tfplan"`; a second plan must report no changes.
