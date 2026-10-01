# Azure App Service Platform Lab

An educational project exploring the design of an application platform in Microsoft Azure.

**Status: Implementation is in preparation.** This repository contains a design summary, a documented directory structure, build logs, and an initial Terraform configuration for the development foundation layer. No infrastructure resources are defined in Terraform yet, and this configuration has not been used to deploy Azure resources. No application or environment-isolation tests have been run. The capabilities below describe the planned design.

## Planned design

- **Three isolated environments:** development, testing, and production. Each environment will have its own network, identities, Azure Key Vault instances, and Terraform state (infrastructure state).
- **Two Azure subscriptions:** one subscription will host development and testing, while a separate subscription will host production. Development and testing will remain isolated from each other within their shared subscription.
- **Private application entry point:** a Linux application will run in Azure App Service behind a private Azure Application Gateway with WAF (Web Application Firewall).
- **Private endpoints:** the Web App, its deployment endpoint, and the application Key Vault will use Private Endpoints and environment-specific private DNS (Domain Name System) zones, with public access disabled.
- **Private secret access:** the application will read secrets from its own Azure Key Vault through its managed identity.
- **User sign-in:** Microsoft Entra ID (Identity) will authenticate users, and access to the application will be restricted to an assigned group.
- **Three Terraform layers:** layer 0 will hold the persistent foundation, layer 1 the network and operations resources, and layer 2 the application platform. Each layer and environment will have a separate Terraform state.
- **Repeatable environment lifecycle:** Terraform will support repeatable environment creation and controlled removal. After a lab presentation, layer 2 and then layer 1 can be removed while layer 0 remains. Secret recovery and package deletion will respect the configured retention and protection periods.
- **Controlled delivery:** Azure DevOps (development and operations) will handle building, testing, and deployment. The same tested application package will be promoted to production only after approval, without rebuilding it.
- **Governance:** Azure Policy will enforce tags, supported regions, and security settings. Budgets will provide alerts rather than act as hard spending limits.
- **Planned verification:** monitoring and tests will be used to demonstrate application functionality and isolation between environments. These checks are planned and have not yet been performed.

## Current scope

The development foundation layer contains Terraform version constraints, provider settings, input variables, an anonymized configuration example, and a provider dependency lock file. Resource definitions, reusable module implementations, remote state storage, automation workflows, and a license have not been added.

Work records: [01 - Preparation](docs/build-log/01-preparation.md) and [02 - Terraform Configuration](docs/build-log/02-terraform-configuration.md).

Local Terraform directories, infrastructure state, saved plans, real environment configurations, secrets, private keys, and local editor settings are excluded from version control. Anonymized configuration examples may be committed using names such as `dev.example.tfvars`, `dev.example.tfvars.json`, `backend.example.hcl`, or `.env.example`. Examples must contain placeholders rather than real environment values or credentials.

The development foundation's `.terraform.lock.hcl` dependency lock file is versioned to record the selected provider version and checksums. Dependency lock files should remain in version control.

## Repository structure

```text
infra/
  environments/
    development/
      layer-0-foundation/
      layer-1-network-operations/
      layer-2-application/
    testing/
      layer-0-foundation/
      layer-1-network-operations/
      layer-2-application/
    production/
      layer-0-foundation/
      layer-1-network-operations/
      layer-2-application/
  modules/
```

The `infra/` directory holds infrastructure code and descriptions of the planned layers. The development foundation layer contains the initial Terraform configuration; the other layer directories currently contain documentation only. Each environment and layer is intended to have a separate Terraform root configuration (a directory from which Terraform manages a set of resources), with its own Terraform state (infrastructure state). Remote state storage and its access controls have not yet been configured.

| Layer | Planned responsibility | Planned lifecycle |
| --- | --- | --- |
| 0: Foundation | Persistent resources, including infrastructure for storing Terraform state | Retained during routine environment removal |
| 1: Network and operations | The environment's network and operational services | Created before layer 2; removed after layer 2 |
| 2: Application | The environment's application platform | Created after layer 1; removed before layer 1 |

The `infra/modules/` directory will contain reusable Terraform building blocks. Environments will use the same code to create their own resources. Modules will not have independent state; their resources will be tracked in the state of the root configuration that calls them.

## Author

**Peter Hudcovič**

Portfolio: [peterhudcovic.tech](https://peterhudcovic.tech)

The project is listed in the portfolio's “My Projects” section on [peterhudcovic.tech](https://peterhudcovic.tech).
