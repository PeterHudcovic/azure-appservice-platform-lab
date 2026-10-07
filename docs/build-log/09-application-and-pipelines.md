# 09 - Demo Application and Pipelines

**Status:** Completed for development. The demo application is built on a Microsoft-hosted agent, stored as an immutable package, and deployed by the private development application agent. The full user path works: the gateway backend is healthy and the application reads its vault through the private endpoint.

**Execution:** Claude wrote the application and pipelines on the branch `claude/dev-layer2`, created the pipelines through the Azure DevOps REST API, and ran them. Peter authorized the service connections, the agent pool, and the environment in Azure DevOps, and created the GitHub service connection.

## Demo application (`app/`)

| Item | Implementation |
| --- | --- |
| Server | Python standard library WSGI server (`python app.py`), listening on the App Service port |
| `/` | Shows the environment, package version, source commit, signed-in user, requested host, the Key Vault check result, and the application state. Values are HTML-escaped. |
| `/health` | Excluded from sign-in. Returns 200 only when the application identity can read secret metadata from its vault through the Azure SDK (`DefaultAzureCredential`, `SecretClient`); otherwise 503. Secret values are never read or logged. |
| Dependencies | `azure-identity` and `azure-keyvault-secrets`, bundled into the package for Linux and Python 3.12 by the build (`SCM_DO_BUILD_DURING_DEPLOYMENT = false`) |
| Tests | `app/test_app.py`: unknown path, health without and with vault access, HTML escaping |

Layer 2 sets the startup command `python app.py` (`app_command_line`).

## Pipelines (`pipelines/`)

All pipelines read their YAML from GitHub through the service connection `github-peterhudcovic` and live in the Azure DevOps folder `\sits`.

| Pipeline | File | Agent | Identity | Purpose |
| --- | --- | --- | --- | --- |
| `sits-build` | `build.yml` | Microsoft-hosted | `build` | Unit tests, ZIP package with a unique name, `version.json`, SHA-256 manifest, upload to the immutable `packages` container (not for pull requests) |
| `sits-deploy-dev` | `deploy-dev.yml` | `mdp-sits-dev-app-swc` | `dev-deploy` | Triggered by a successful build of `main`; downloads the package, verifies SHA-256, deploys through the private `.scm` endpoint with Entra ID, checks `/health` and that `/` requires sign-in |
| `sits-infra-dev-l1` | `infra-dev-l1.yml` | Microsoft-hosted | `dev-infra-l1` | Terraform for layer 1 (created, not run yet) |
| `sits-infra-dev-l2` | `infra-dev-l2.yml` | `mdp-sits-dev-infra-swc` | `dev-infra-l2` | Terraform for layer 2 (created, not run yet) |
| `sits-destroy-dev` | `destroy-dev.yml` | infrastructure pool, then Microsoft-hosted | `dev-destroy` | Destroys layer 2, then layer 1 (created, never run) |

Shared templates: `templates/terraform-steps.yml` (Terraform install, subscription check, OIDC authentication with the service connection token, plan and apply) and `templates/deploy-steps.yml` (package verification and deployment, health and sign-in checks). `deploy-test.yml` uses the same template for testing.

Every pipeline stops before any change when the service connection points to an unexpected subscription. Azure DevOps environments `dev` and `dev-destroy` were created through the REST API.

## Checks

| Check | Result |
| --- | --- |
| Local unit tests | 4 of 4 passed |
| Microsoft-hosted parallel jobs for private projects | 1 free job available |
| Build run `20261005.1` | Succeeded; package `sits-app-20261005.1-<commit>.zip` and its manifest stored in `packages` |
| Deploy run 2 | Package verified (SHA-256 OK) and deployed, but `az webapp deploy` reported a start timeout (see Issues) |
| Deploy run 3 (same package) | Succeeded: verification, deployment, health check, sign-in check |
| Health through the private endpoint from the application agent | HTTP 200, `{"status": "healthy", "environment": "dev", "version": "20261005.1", "keyVault": {"ok": true, ...}}` |
| Anonymous request to `/` | HTTP 401 (sign-in required) |
| Gateway backend health | Healthy |
| App Service console logs in Log Analytics | Platform health probes on `/health` return 200 |
| End-to-end test by Peter from the development Ops VM: `https://app.dev.sits.internal` | Demo page through the WAF after Entra ID sign-in: environment `dev`, package `20261005.1`, signed-in user Lab Admin (member of `grp-sits-dev-app-users`), Key Vault check OK. Sign-in without a client secret (federated credential on the application identity) works. The browser shows "Not secure", because the Ops VM does not trust the self-signed WAF certificate yet. |

## Issues and fixes

- The startup command was applied before the first deployment, so the container exited (no `app.py`, exit code 2) until App Service blocked cold starts for a few minutes. The first deployment arrived during the block; the site then started with this deployment, but the deployment status tracking had already timed out. A second run of the same package succeeded. Lesson: deploy code before or together with a custom startup command.
- Pipelines queued through the REST API do not create environments automatically; `dev` and `dev-destroy` were created explicitly.
- A manual run of the deploy pipeline uses the latest build of the default branch; the run request names the build run explicitly while the work is on a feature branch.
- `az monitor log-analytics query` needs an extension; the Log Analytics query API was used instead.

## Open items

- `sits-infra-dev-l1` and `sits-infra-dev-l2` need additional roles before they can take over from the local runs (layer 0 reads, network join, private DNS, Network Watcher, flow log storage). Until then `temporary.tf` stays.
- Branch policies on `main`, approvals and branch checks on the service connections and pools (configured with production).
- Trust the public part of the self-signed WAF certificate on the Ops VM (Trusted Root store, through a VM extension in layer 1 as the design describes), so the browser no longer shows "Not secure".

## Next step

Testing environment layers 0, 1, and 2.
