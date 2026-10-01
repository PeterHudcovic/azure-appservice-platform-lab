# Development — Layer 0: Foundation

**Planned scope:** Persistent foundation resources for the development environment in the non-production subscription, including infrastructure for storing Terraform state (infrastructure state).

**Planned lifecycle:** This layer will remain in place when layers 2 and 1 are removed. State-storage bootstrap and recovery will be designed before deployment.

This directory contains the initial Terraform root configuration for the development foundation. It will manage its own Terraform state (infrastructure state), separate from other environments and layers.

**Status: Implementation is in preparation.** This directory contains an initial Terraform configuration with version constraints, provider settings, input variables, an anonymized configuration example, and a provider dependency lock file. No resource definitions or remote state backend are configured. This configuration has not been used to deploy Azure resources.
