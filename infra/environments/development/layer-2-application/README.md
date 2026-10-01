# Development — Layer 2: Application

**Planned scope:** The application platform for the development environment in the non-production subscription, including Azure App Service, the application Key Vault, and application identities.

**Planned lifecycle:** This layer will be created after layer 1 and removed before layer 1 during routine environment removal.

This directory will become a separate Terraform root configuration with its own Terraform state (infrastructure state), separate from other environments and layers.

**Status: Implementation is in preparation.** This directory contains documentation only; no resources or state backend are configured.
