# Scalr and OpenTofu

Scalr supports OpenTofu as a native run engine. Phase 0 uses OpenTofu 1.13.x, which is past the Terraform versions Scalr will run, so Scalr workspaces for this service must set the IaC platform to OpenTofu.

## Finding

Scalr runs OpenTofu. It is not a Terraform-only backend with a side door.

- The product introduction describes Scalr as a remote operations backend for Terraform and OpenTofu, executing runs and storing state either in Scalr or in a backend you choose. Source: [What is Scalr?](https://docs.scalr.io/docs/introduction) (page updated about August 2026).
- Each workspace has an IaC platform of either Terraform or OpenTofu. Scalr's own pipeline settings say Terraform can be used up until 1.5.7 and that anything beyond that should use OpenTofu. The version can be taken from `required_version` in the root module. Source: [IAC Platform/Pipeline Settings](https://docs.scalr.io/docs/iac-platform) (page updated about August 2026).
- The workspace resource exposes `iac_platform` with valid values `terraform` and `opentofu`, defaulting to `terraform`. Source: [scalr_workspace](https://docs.scalr.io/docs/provider_resource_scalr_workspace) (page updated 13 October 2026).
- OpenTofu is available to every workspace by default. The account integrations page can add `opentofu validate` and `opentofu fmt` during init. A run that fails those checks stops during init and does not count toward billing. Source: [OpenTofu](https://docs.scalr.io/docs/opentofu) (page updated about August 2025).
- The OpenTofu FAQ says Scalr can execute a run with OpenTofu, that Terraform 0.14.x through 1.5.x remain available, and that versions above 1.5.x should use OpenTofu. Source: [OpenTofu FAQ](https://docs.scalr.io/docs/opentf-faq) (page updated about August 2025).

Consequence for this repo: set `iac_platform = "opentofu"` on every workspace. Do not leave the default `terraform`. The root modules here declare `required_version = ">= 1.8.0, < 2.0.0"`, which only resolves on OpenTofu.

Client-side state encryption (OpenTofu 1.7+) still runs, but Scalr will not show resources and outputs for those workspaces and its reporting will not work. This phase does not enable state encryption. Source: [IAC Platform/Pipeline Settings](https://docs.scalr.io/docs/iac-platform).

State for Phase 0 lives in the per-client GCS bucket from `infra/modules/bootstrap-state`, not in Scalr's built-in backend. Disable the Scalr backend on the workspace so the GCS backend in the root module is the one that runs. The same pipeline page describes that switch.

## Agent

Scalr's control plane stays SaaS. Runs execute on a self-hosted agent so the worker can reach the client's private APIs only through Google APIs (there is no customer VPC in this phase; the agent still keeps the run off Scalr's hosted runners if policy requires it).

Official references:

- [Installation](https://docs.scalr.io/docs/installation)
- [Configuration Options](https://docs.scalr.io/docs/configuration)
- [Drivers](https://docs.scalr.io/docs/drivers)
- [Create an Agent Pool](https://docs.scalr.io/reference/create_agent_pool)

### Pool

Create the pool at account scope if every client environment will share the workers, or at environment scope if a client must be isolated. Create a pool token in Scalr. The token is how the agent joins the pool. Store it in the host's secret store or an env file outside this repository. Do not commit it, and do not put it in a Scalr variable that is marked as a shell variable exported into the run.

### Process

The Docker driver isolates each run stage in its own container. The agent needs the Docker socket and a persistent data directory. Pin the image tag you have reviewed; `latest` is what the upstream install snippet uses, and a production host should pin a digest after that review.

```yaml
services:
  scalr-agent:
    image: scalr/agent:latest
    container_name: scalr-agent
    restart: unless-stopped
    env_file:
      - /etc/scalr-agent/agent.env
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/scalr-agent:/var/lib/scalr-agent
    pull_policy: always
```

`/etc/scalr-agent/agent.env` is mode `0600` and contains only:

```text
SCALR_AGENT_TOKEN=<pool token from the Scalr UI>
SCALR_AGENT_DRIVER=docker
```

`SCALR_AGENT_DATA_DIR` defaults to the mounted data directory. Do not bake the token into the image or the compose file.

The Docker driver mounts the OpenTofu working directory at `/opt/workdir` inside the task container. Provider plugins are cached under `/opt/providers`. See [Drivers](https://docs.scalr.io/docs/drivers).

Agent 2.0.0 changes the default task network to `bridge`. A bridge network cannot reach services bound to localhost on the agent host. GCP Workload Identity does not need the host's metadata server when the workspace uses Scalr's OIDC provider configuration, so `bridge` is the right default. Set `SCALR_AGENT_DOCKER_NETWORK` only for a reviewed exception. Source: [Configuration Options](https://docs.scalr.io/docs/configuration).

### Workspace

- IaC platform: `opentofu`.
- Working directory: `infra/live/<client>`.
- VCS: `Q-Labz/universal-cloud`.
- Execution: agent pool created above.
- Auto-apply: off. Apply is an approval in Scalr.
- Scalr remote backend: disabled, so the GCS backend in the client root is authoritative.
- Provider configuration: GCP OIDC, not a service account key. The JSON key method is documented by Scalr and is not used here.

The GCP OIDC provider configuration points at the provider this repo creates:

- Issuer `https://scalr.io` (exact match).
- `workload_provider_name` = the `scalr_workload_identity_provider` output.
- `service_account_email` = the apply service account for apply, and a second provider configuration using the plan service account for plan.

Scalr's GCP documentation says a single OIDC provider configuration is linked to a workspace, and that `apply_only` is currently an AWS feature. This repo therefore splits plan and apply inside Google by the `scalr_run_phase` claim: the plan service account's binding requires `attribute.scalr_run_phase == 'plan'`, and the apply service account's binding requires `attribute.scalr_run_phase == 'apply'`. The published token sample shows `"scalr_run_phase": "plan"` and says a token is exported for each run phase (plan and apply). Sources: [GCP Provider Configuration](https://docs.scalr.io/docs/google), [Terraform & OpenTofu Runs](https://docs.scalr.io/docs/workspaces-runs).

Confirm the apply-phase claim value with a decoded token before the first real apply. If Scalr ever sends a different string, the apply binding fails closed.

Example provider configuration, for the Scalr account, not for this repository:

```hcl
resource "scalr_provider_configuration" "gcp_plan" {
  name       = "example-client-plan"
  account_id = "acc-exampleplaceholder"

  google {
    auth_type              = "oidc"
    project                = "example-client-app"
    service_account_email  = "example-client-plan@example-client-app.iam.gserviceaccount.com"
    workload_provider_name = "projects/000000000000/locations/global/workloadIdentityPools/example-client-wif/providers/scalr-agent"
  }
}
```

Link plan and apply carefully. Until Scalr supports `apply_only` for GCP, the practical split is the Google IAM condition on `scalr_run_phase`. Do not upload a JSON key into the provider configuration.

## GitHub Actions fallback

If the agent is down, `.github/workflows/tofu.yml` is the fallback. It uses the same workload identity pool's GitHub provider and the same plan and apply service accounts. It does not read repository secrets. See the runbook for the variable names and the `gcp-apply` environment.
