# Development — Layer 0: Foundation

**Planned scope:** Persistent foundation resources for the development environment in the non-production subscription, including infrastructure for storing Terraform state (infrastructure state).

**Planned lifecycle:** This layer will remain in place when layers 2 and 1 are removed. State-storage bootstrap and recovery will be designed before deployment.

This directory will become a separate Terraform root configuration with its own Terraform state (infrastructure state), separate from other environments and layers.

**Status: Implementation is in preparation.** This directory contains documentation only; no resources or state backend are configured.
