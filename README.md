# Azure App Service Platform Lab

An educational project exploring the design of an application platform in Microsoft Azure.

**Status: Implementation is in preparation.** This repository currently contains only an introductory design summary and version-control exclusions. No Azure resources have been deployed for this project, and no application, infrastructure, or environment-isolation tests have been run. The capabilities below describe the planned design, not a working platform.

## Planned design

- **Three isolated environments:** development, testing, and production. Each environment will have its own network, identities, Azure Key Vault instances, and Terraform state (infrastructure state).
- **Two Azure subscriptions:** one subscription will host development and testing, while a separate subscription will host production. Development and testing will remain isolated from each other within their shared subscription.
- **Private application entry point:** a Linux application will run in Azure App Service behind a private Azure Application Gateway with WAF (Web Application Firewall).
- **Private secret access:** Azure Key Vault will use private access. The application will read secrets through its managed identity.
- **Repeatable environment lifecycle:** Terraform will support repeatable environment creation and controlled removal. A persistent foundation will remain in place when disposable environment resources are removed.
- **Controlled delivery:** Azure DevOps (development and operations) will handle building, testing, and deployment. The same tested application package will be promoted to production only after approval, without rebuilding it.
- **Planned verification:** monitoring and tests will be used to demonstrate application functionality and isolation between environments. These checks are planned and have not yet been performed.

## Current scope

This initial repository contains only this README and a `.gitignore` file. Terraform implementation, automation workflows, deployment, and a license have not been added.

Local Terraform directories, infrastructure state, saved plans, real environment configurations, secrets, private keys, and local editor settings are excluded from version control. Anonymized configuration examples may be committed using names such as `development.example.tfvars`, `development.example.tfvars.json`, `backend.example.hcl`, or `.env.example`. Examples must contain placeholders rather than real environment values or credentials.

The `.terraform.lock.hcl` dependency lock file will remain eligible for version control when Terraform implementation is added.

## Author

**Peter Hudcovič**

Portfolio: [peterhudcovic.tech](https://peterhudcovic.tech)

The project is intended for a future entry in the portfolio's “My Projects” section. The portfolio website is not being updated as part of this initial repository setup.
