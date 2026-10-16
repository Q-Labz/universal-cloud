# identity

Creates, in the client project:

- One Workload Identity Federation pool.
- A GitHub Actions OIDC provider. The attribute condition requires `assertion.repository_owner == "Q-Labz"` and `assertion.repository` equal to `github_repository` (itself required to be `Q-Labz/<repo>`). The default repository is `Q-Labz/universal-cloud`.
- A Scalr OIDC provider. The issuer is `https://scalr.io` and the attribute condition requires an exact `assertion.scalr_account_id` match. Attribute mappings follow the [Scalr GCP provider configuration](https://docs.scalr.io/docs/google).
- A plan service account and an apply service account. This module does not create service account keys.

The plan service account receives only viewer-level predefined roles. The list is an allowlist. On the project the defaults are `roles/viewer`, `roles/iam.securityReviewer`, and `roles/serviceusage.serviceUsageViewer`. When a billing account id is set, it also receives `roles/billing.viewer` on that account.

The apply service account receives least-privilege predefined roles for the resources this phase manages (network, instances, Cloud SQL, Private Service Access, API enablement, logging config, storage, BigQuery, and service account administration). It does not receive a basic primitive admin role, and it does not receive `roles/resourcemanager.projectIamAdmin`. Variable validation rejects the two basic primitive admin roles. When a billing account id is set, the apply account receives `roles/billing.user` on that account so it can link a project.

Impersonation:

- GitHub plan: any token for the locked repository (the provider already rejected every other org and repo).
- GitHub apply: only the `refs/heads/main` subject.
- Scalr plan: the locked account id, and only when `attribute.scalr_run_phase` is `plan`.
- Scalr apply: the locked account id, and only when `attribute.scalr_run_phase` is `apply`.

The published Scalr OIDC sample uses `"scalr_run_phase": "plan"` and states that a token is issued for each run phase (plan and apply). See [Terraform & OpenTofu Runs](https://docs.scalr.io/docs/workspaces-runs).

## Example

```hcl
module "identity" {
  source = "../../modules/identity"

  project_id         = module.project.project_id
  client_id          = "example-client"
  github_repository  = "Q-Labz/universal-cloud"
  scalr_account_id   = "acc-exampleplaceholder"
  folder_id          = module.landing_zone.client_folder_name
  billing_account_id = "000000-000000-000000"
}
```

## Validate

```bash
tofu init -backend=false
tofu validate
```
