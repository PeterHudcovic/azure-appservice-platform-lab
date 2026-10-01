# Production — Layer 1: Network and operations

**Planned scope:** The dedicated network and operational services for the production environment in the production subscription.

**Planned lifecycle:** This layer will be created after layer 0 and before layer 2. Routine environment removal will remove layer 2 before this layer.

This directory will become a separate Terraform root configuration with its own Terraform state (infrastructure state), separate from other environments and layers.

**Status: Implementation is in preparation.** This directory contains documentation only; no resources or state backend are configured.
