# Azure App Service Platform Lab

An educational project exploring the design of an application platform in Microsoft Azure.

**Status: Built.** Development, testing, and production are deployed with Terraform in three layers each, and a demo application is delivered through Azure DevOps pipelines. The detailed results, deviations, and open items are in the [build records](docs/build-log/).

## Design

- **Three isolated environments:** development, testing, and production, each with its own network, identities, Azure Key Vault instances, and Terraform state (infrastructure state).
- **Two Azure subscriptions:** one for development and testing, a separate Pay-As-You-Go subscription for production. Development and testing stay isolated within their shared subscription (no peering).
- **Private application entry point:** a Linux application in Azure App Service behind a private Azure Application Gateway with WAF (Web Application Firewall). Users reach it only from the Ops VM (operations virtual machine) through Azure Bastion.
- **Private endpoints:** the Web App, its deployment endpoint, and the application Key Vault use private endpoints and environment-specific private DNS (Domain Name System) zones, with public access disabled.
- **Private secret access:** the application reads its own Key Vault through its managed identity; secrets never appear in settings or logs.
- **User sign-in:** Microsoft Entra ID (Identity) authenticates users, only an assigned group is admitted, and the app registration has no client secret (it trusts the application managed identity).
- **Three Terraform layers:** layer 0 the persistent foundation, layer 1 the network and operations resources, layer 2 the application platform; each layer and environment has its own state.
- **Repeatable lifecycle:** layer 2 and then layer 1 can be removed while layer 0 remains; the application vault returns from soft delete with its secrets.
- **Controlled delivery:** Azure DevOps builds one immutable package with a SHA-256 fingerprint; development and testing deploy it automatically, production only after approval, without rebuilding it. Private Managed DevOps Pools agents deploy through the private endpoints.
- **Governance:** Azure Policy for tags, the allowed region, HTTPS and TLS on web apps, and no public Key Vault access; budgets with alerts; in production PIM (Privileged Identity Management), report-only Conditional Access, and delete locks.

## Repository structure

```text
app/                         Demo application (page and /health) and its unit tests
pipelines/                   Azure DevOps pipelines and shared templates
infra/
  environments/
    development/  testing/  production/
      layer-0-foundation/
      layer-1-network-operations/
      layer-2-application/
  modules/                   Reserved for the planned refactor into reusable modules
docs/build-log/              Step-by-step build records
```

| Layer | Responsibility | Lifecycle |
| --- | --- | --- |
| 0: Foundation | State storage, identities, vaults for the WAF certificate and emergency password, monitoring, policy, roles | Retained |
| 1: Network and operations | Virtual network, network security, NAT, private DNS, vault private endpoints, Ops VM, Bastion, flow logs, private agent pools | Created before layer 2, removed after it |
| 2: Application | Application vault, App Service, Application Gateway with WAF, DNS record, diagnostics | Created after layer 1, removed before it |

Testing and production are copies of the development layers with environment values. Moving the shared code into `infra/modules/` is a planned next step.

## Configuration files

Local Terraform directories, infrastructure state, saved plans, real environment values (`*.tfvars`, `backend.hcl`), secrets, private keys, and local editor settings are excluded from version control. Each layer has anonymized examples (`*.example.tfvars`, `backend.example.hcl`) with placeholders only. Dependency lock files (`.terraform.lock.hcl`) are versioned.

## Author

**Peter Hudcovič**

Portfolio: [peterhudcovic.tech](https://peterhudcovic.tech)

The project is listed in the portfolio's “My Projects” section on [peterhudcovic.tech](https://peterhudcovic.tech).
