# GCP client runbook

How to operate one managed GCP client before a dashboard exists. Phase 0 is OpenTofu under `infra/`. The example root at `infra/live/example-client` uses placeholder ids and must not be applied.

Two runners are supported. Scalr is the primary runner and it does run OpenTofu; details and sources are in [scalr.md](scalr.md). GitHub Actions is the fallback when the agent is unavailable.

No service account keys are created. Access is Workload Identity Federation only. The basic primitive roles `roles/editor` and `roles/owner` are forbidden. `infra/ci/forbid-privileged-iam.sh` fails the build if either string appears in OpenTofu, tfvars, or workflow files, and it also fails if a `google_service_account_key` resource or a PEM private key appears.

## Who does what

| Identity | What it can do |
| --- | --- |
| Organization admin (human, break-glass) | First apply of a new client: folders, project, billing link, state bucket, workload identity pool. Not stored in this repo. |
| Plan service account | Read the client project and folder. Read billing. Read state (`-lock=false`). Cannot change infrastructure. |
| Apply service account | Create and update the network, VMs, Cloud SQL, log sinks, and APIs inside the client project. Storage admin on the state bucket. Billing user on the linked billing account. Folder creator, folder editor, and organization policy admin on the client folder. |
| VM runtime service account | Attached to the instance. No project roles. |

The apply service account does not have project IAM admin, so it cannot grant itself a broader role. Granting a new project role is a break-glass change reviewed in Git.

## Onboarding a client

Do this once per client. Replace every placeholder before the first real plan. Do not reuse `infra/live/example-client` as the applied root. Copy it to `infra/live/<client-id>/` and change the ids in that copy.

### 1. Landing zone and project

As an organization admin, with Application Default Credentials for that admin (a user login, not a key file committed anywhere):

1. Set `parent` to the real organization or folder (`organizations/123` or `folders/123`).
2. Set `billing_account` to the real billing account id.
3. Set `project_id` to a globally unique id.
4. From the new client root, with no `backend.tf` yet:

```bash
tofu init -backend=false
tofu plan -out=tfplan
```

Review the plan. The first apply creates the folder, the project, the billing link, the pool, and the state bucket. Apply it with the organization admin, then throw the local plan file away.

```bash
tofu apply tfplan
```

Record the outputs:

- `state_bucket_name`
- `github_workload_identity_provider`
- `scalr_workload_identity_provider`
- `plan_service_account_email`
- `apply_service_account_email`
- `client_folder_name`

### 2. State backend

The bootstrap-state module created one versioned bucket in the client project. Uniform bucket-level access and public access prevention are on. Noncurrent versions expire after 90 days and are also capped at 30 newer versions.

Add `backend.tf` to the client root, using the bucket output. One bucket per client. One prefix per stack.

```hcl
terraform {
  backend "gcs" {
    bucket = "CLIENT_STATE_BUCKET"
    prefix = "stacks/foundation"
  }
}
```

Migrate the local state from the first apply into that bucket:

```bash
tofu init -migrate-state
```

Confirm the prompt names the new bucket. After migration, delete the local `terraform.tfstate` and do not commit it. Later stacks for the same client use the same bucket and a different prefix.

From here on, plan and apply use the service accounts below, not the organization admin, except for break-glass.

### 3. Workload identity and service accounts

The identity module has already created:

- Pool `<client-id>-wif`.
- Provider `github-actions`. Attribute condition: repository owner is `Q-Labz` and repository is `Q-Labz/<repo>` (default `Q-Labz/universal-cloud`).
- Provider `scalr-agent`. Issuer `https://scalr.io`. Attribute condition: Scalr account id matches the client variable exactly.
- Plan and apply service accounts, with no keys.

GitHub can assume plan for any workflow in that repository. GitHub can assume apply only for the subject `repo:Q-Labz/<repo>:ref:refs/heads/main`. Scalr can assume plan only when the token's `scalr_run_phase` is `plan`, and apply only when it is `apply`.

### 4. GitHub Actions variables

These are repository or environment variables, not secrets. Do not create a JSON key and do not add a `secrets.` entry for them.

| Name | Where | Value |
| --- | --- | --- |
| `WORKLOAD_IDENTITY_PROVIDER` | Repository variable | `github_workload_identity_provider` output |
| `GCP_PLAN_SERVICE_ACCOUNT` | Repository variable | plan service account email |
| `GCP_APPLY_SERVICE_ACCOUNT` | Environment `gcp-apply` | apply service account email |
| `TOFU_STACK` | Repository variable | `infra/live/<client-id>` |
| `TOFU_PLAN_ENABLED` | Repository variable | `true` once `TOFU_STACK` points at a real client |

Create a GitHub environment named `gcp-apply` and add required reviewers. The apply job is bound to that environment, so a dispatch waits for approval. The workflow file cannot create the reviewer list; an organization owner does that in the environment settings. Until reviewers are required, do not set `TOFU_PLAN_ENABLED` and do not dispatch apply.

The workflow refuses any stack path containing `example-client`.

### 5. Scalr

Follow [scalr.md](scalr.md). In short: agent pool and token outside git, workspace IaC platform `opentofu`, Scalr backend disabled, GCP OIDC provider configuration using the outputs above, auto-apply off.

## Plan and apply

### Pull request

On a pull request that touches `infra/`, GitHub Actions always runs:

1. The privileged-IAM script.
2. `tofu fmt -check -recursive`.
3. `tofu init -backend=false` and `tofu validate` in every module and live root.
4. TFLint with the pinned Google and Terraform rulesets.

That path does not call GCP. A plan runs in the same workflow only when `TOFU_PLAN_ENABLED` is `true` and `TOFU_STACK` is a real client root. Plan authenticates with workload identity as the plan service account and uses `tofu plan -lock=false`, because that account cannot write the lock object.

Review the plan in the workflow log, or in the Scalr run if the agent is healthy. Prefer Scalr when both are green; they should describe the same change.

### Apply

Apply is manual.

GitHub fallback:

1. Actions, OpenTofu, Run workflow.
2. Action: `apply`. Stack: `infra/live/<client-id>`.
3. A required reviewer approves the `gcp-apply` environment.
4. The job authenticates as the apply service account, writes a plan, and applies that plan file.

Scalr:

1. The pull request run is a plan.
2. An approver runs apply in Scalr. The apply token can assume only the apply service account.

Do not run apply from a laptop with a downloaded key. A break-glass admin apply uses user ADC and is written down in the incident channel.

## Add a VM

In the client root, add a key under `module.vm.instances`. Use an N2 machine type (the default is `n2-standard-2`). E2 does not support Shielded VM, which this module always turns on.

```hcl
instances = {
  app = {
    zone         = "us-central1-a"
    machine_type = "n2-standard-2"
    subnetwork   = module.network.subnet_self_links["app"]
  }
  worker = {
    zone         = "us-central1-b"
    machine_type = "n2-standard-2"
    subnetwork   = module.network.subnet_self_links["app"]
  }
}
```

The new instance has no external IP, OS Login, Shielded VM, and its own runtime service account with no project roles. SSH is `gcloud compute ssh <name> --tunnel-through-iap`. The human also needs `roles/compute.osAdminLogin` (or `roles/compute.osLogin`) on the project, granted by a break-glass admin to that human, not to the apply service account.

Open a pull request. Plan, review, then apply through the flow above.

## Add a database

The first instance is already in the example composition and owns the Private Service Access peering. A second instance on the same VPC must not create another peering.

```hcl
module "sql_reporting" {
  source = "../../modules/cloud-sql"

  project_id                     = module.project.project_id
  region                         = var.region
  name                           = "${var.client_id}-reporting"
  network_self_link              = module.network.network_self_link
  manage_private_service_access = false
  allocated_ip_range             = module.sql.psa_range_name
  database_name                  = "reporting"
  labels                         = var.labels
}
```

Public IP cannot be turned on in the module (`ipv4_enabled` is hard-coded false), and the folder organization policy `sql.restrictPublicIp` blocks it at the platform. The module does not create a database user or a password. Connect with the Cloud SQL Auth Proxy over the private IP, or with IAM database authentication added in a follow-up.

Backups run at 03:00 and keep 14 copies. Point-in-time recovery is on for PostgreSQL. Disk autoresize stops at 100 GB unless you change `disk_autoresize_limit_gb`.

## Rotate access

There are no keys to rotate.

GitHub or Scalr identity is suspected:

1. In the client root, set no new principals. The providers only trust the Q-Labz repository and one Scalr account id.
2. To cut access immediately, set `disabled = true` on `google_iam_workload_identity_pool.this` in a break-glass apply, or disable the pool in the console. Every token stops working.
3. Re-enable the pool after the investigation. Pool and provider ids stay the same, so the GitHub variables do not change.
4. Rotate the Scalr agent pool token in the Scalr UI, replace `/etc/scalr-agent/agent.env` on the host, and restart the container. The old token stops joining.

A person leaves the org:

1. Remove them from the GitHub repository and from the `gcp-apply` reviewers.
2. Remove them from Scalr.
3. If they had break-glass GCP access, remove that IAM binding in the console and confirm with `gcloud projects get-iam-policy`.

Do not create a key as a workaround. The organization policy `iam.disableServiceAccountKeyCreation` on the client folder blocks key creation. An exception is a temporary policy change by an organization admin, recorded in the incident channel, and reverted the same day.

## Incident response

1. Say what clients are affected and freeze apply. In Scalr, stop the workspace or set it to read-only. In GitHub, leave `gcp-apply` reviewers in place and do not dispatch.
2. Disable the workload identity pool if the runner or a workflow is the suspected path. Management through the organization admin still works.
3. Read logs before changing infrastructure.
   - Audit and error logs are in the sink destination (the log bucket, or BigQuery if the client switched). The default filter is Admin Activity, System Event, Policy Denied, and severity ERROR and above.
   - Firewall denies are logged on the default-deny rules.
   - Cloud NAT error logs are on the router.
   - VPC flow logs are on each subnet at a 0.5 sample.
4. A bad apply: roll state back using the section below, then plan. Do not fix drift by clicking in the console unless the console change is the only way to stop bleeding; import or revert that click afterwards.
5. A public IP or a public bucket: the organization policies should have blocked it. If one exists, it was created outside this stack or the policy was overridden. Delete the exposure, then plan to see the drift.
6. Re-enable the pool only after the plan service account's next plan matches the restored state.

Contacts and paging are outside this phase. Write the incident in the client channel and link the plan that repaired it.

## Roll back with state versions

The state bucket is versioned. Every apply writes a new generation of the state object. The previous generation is the rollback point.

1. Freeze apply.
2. List generations. The object name is `stacks/<stack>/default.tfstate` for a GCS backend prefix of `stacks/<stack>`.

```bash
gcloud storage ls --all-versions \
  "gs://CLIENT_STATE_BUCKET/stacks/foundation/default.tfstate"
```

3. Copy the current generation aside.

```bash
gcloud storage cp \
  "gs://CLIENT_STATE_BUCKET/stacks/foundation/default.tfstate" \
  "gs://CLIENT_STATE_BUCKET/stacks/foundation/default.tfstate.bak"
```

4. Copy the last known-good generation onto the live object name. Use the generation number from the listing.

```bash
gcloud storage cp \
  "gs://CLIENT_STATE_BUCKET/stacks/foundation/default.tfstate#GENERATION" \
  "gs://CLIENT_STATE_BUCKET/stacks/foundation/default.tfstate"
```

5. As the plan service account (or the organization admin), run `tofu plan -lock=false`. The plan is the inverse of the bad apply. Review it.
6. Apply that plan with the apply service account only if restoring the previous infrastructure is what you want. If the bad apply created a resource that still exists, the plan will propose to change or destroy it. Read every destroy.
7. Noncurrent generations are deleted after 90 days or after 30 newer versions. Do not disable versioning on this bucket.

Rolling state back does not roll the Git commit back. Revert the commit too, or the next plan will re-apply the bad change.

## Cost and logs

Cost, without a dashboard:

```bash
gcloud billing accounts get-iam-policy BILLING_ACCOUNT
gcloud billing projects describe PROJECT_ID
```

The plan service account has `roles/billing.viewer` on the billing account, so a human who can impersonate it, or the billing console filtered to the project, can see charges. For a point check of SKUs:

```bash
gcloud billing budgets list --billing-account=BILLING_ACCOUNT
```

Budgets are not created by Phase 0. Create one in the billing account for the project if the client does not already have one, and point it at the people who approve apply.

Logs:

```bash
gcloud logging read \
  'log_id("cloudaudit.googleapis.com/activity") OR severity>=ERROR' \
  --project=PROJECT_ID \
  --freshness=1d \
  --limit=50
```

The folder sink is the retention copy. The project still holds the originals for the default retention window. The sink bucket deletes objects after 365 days. If the client needs longer retention, raise `retention_days` in a reviewed change. Exporting every log (`filter = ""`) is a cost change and needs an explicit reason in the pull request.

## What this phase does not do

- It does not apply the example root.
- It does not create service account keys.
- It does not grant `roles/editor` or `roles/owner`.
- It does not ship a dashboard, a ticketing integration, or budget resources.
- It does not open SSH to the internet. Administration is Identity-Aware Proxy plus OS Login.
