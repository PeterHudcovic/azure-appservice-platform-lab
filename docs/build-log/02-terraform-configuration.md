# 02 - Terraform Configuration

**Status:** Initial configuration recorded. No Azure resources have been deployed.

## Configuration

Peter created the initial Terraform configuration in `infra/environments/development/layer-0-foundation/` with guidance from Codex.

| File | Purpose |
| --- | --- |
| `versions.tf` | Terraform and provider version constraints |
| `providers.tf` | Azure Resource Manager provider configuration |
| `variables.tf` | Input variable declarations |
| `development.example.tfvars` | Example development variable values |
| `.terraform.lock.hcl` | Locked provider selections and checksums |

The Terraform version constraint is `~> 1.16.2`. The AzureRM (Azure Resource Manager) provider constraint is `~> 5.7.0`.

The real development configuration remains in the ignored `development.tfvars` file. Its contents and identifiers are intentionally excluded from this record.

## Review and Reported Check

- Git ignore output and the staged diff were reviewed.
- Peter reported that the Terraform console returned the expected `swedencentral` value.

## Scope and Open Items

No resource definitions, remote backend, or automation pipelines are implemented. No Azure deployment or application and environment-isolation tests were performed.

Resource ownership and state-storage bootstrap remain to be agreed.