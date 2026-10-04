# Development - Layer 0: Foundation

**Scope:** Persistent foundation resources for the development environment in the non-production subscription.

**Lifecycle:** This layer remains in place when layers 2 and 1 are removed. It is never destroyed as part of the normal workflow.

This directory is the Terraform root configuration for the development foundation. It manages its own Terraform state (infrastructure state), separate from other environments and layers.

**Status: In progress.** Implemented: the Terraform state storage account `stsitstfdevswc` (shared key access disabled, Microsoft Entra ID only), one private state container per layer, and a data role for the layer 0 operator. The state of this layer is stored in the blob `development-layer0.tfstate` in the container `tfstate-layer0`. Other foundation resources are not implemented yet. Details: [03 - Development State Bootstrap](../../../../docs/build-log/03-development-state-bootstrap.md).

## Usage

Sign in to Azure CLI (Command-Line Interface) with the Lab Admin account and check the signed-in account before each run. Then:

1. Copy `backend.example.hcl` to `backend.hcl` and `development.example.tfvars` to `development.tfvars`, and fill in the real values. Both files are ignored by Git.
2. `terraform init -backend-config="backend.hcl"`
3. `terraform plan -var-file="development.tfvars"`