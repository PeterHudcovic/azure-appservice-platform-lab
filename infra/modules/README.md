# Reusable infrastructure modules

This directory is reserved for Terraform building blocks that can be used by multiple environment layers.

Reusing a module will reuse its code. Each environment will create and manage its own resource instances through its own root configurations and Terraform state (infrastructure state). A module will not have a separate state of its own.

**Status: Implementation is in preparation.** No Terraform modules have been implemented.
