# Development - Layer 2: Application

**Scope:** The application platform for the development environment in the non-production subscription: the application Key Vault, the App Service plan and Linux Web App, their private endpoints, Entra ID sign-in, the Application Gateway with WAF (Web Application Firewall), the application DNS (Domain Name System) record, and diagnostic settings.

**Lifecycle:** This layer is created after layer 1 and removed before layer 1. The application vault has a fixed name: a destroy leaves it in soft-delete, and the next apply recovers it with its secrets.

This directory is a separate Terraform root configuration. Its state is stored in the blob `development-layer2.tfstate` in the container `tfstate-layer2`.

**Status: Prepared, not applied.** The configuration passes `terraform validate`. No resources of this layer exist yet.

## Contents

| File | Resources |
| --- | --- |
| `main.tf` | Lookups of layer 0 and layer 1 resources by their fixed names, outputs |
| `keyvault.tf` | Application vault (private, RBAC (role-based access control), no trusted services bypass), private endpoint, application security group association |
| `appservice.tf` | App Service plan (B1), Linux Web App (Python 3.12, VNet integration, private endpoint, Entra ID sign-in without a client secret) |
| `gateway.tf` | WAF policy (Microsoft default rule set, Detection mode), Application Gateway WAF_v2 with a private address only, `app` record in `dev.sits.internal` |
| `diagnostics.tf` | Diagnostic settings of the vault, Web App, gateway, and plan to the development Log Analytics workspace |

Layer 0 grants the application identity Key Vault Secrets User on the Key Vault resource group (`application-vault-access.tf`), so the layer 2 identity never assigns roles. No secrets are written by Terraform.

## Usage

Sign in to Azure CLI (Command-Line Interface) with the Lab Admin account and check the signed-in account before each run. Layer 2 is built locally with the temporary state role from `temporary.tf` in layer 0 until the `dev-infra-l2` pipeline takes over.

1. Copy `backend.example.hcl` to `backend.hcl` and `development.example.tfvars` to `development.tfvars`, and fill in the real values. Both files are ignored by Git.
2. `terraform init -backend-config="backend.hcl"`
3. `terraform plan -var-file="development.tfvars" -out="tfplan"`
