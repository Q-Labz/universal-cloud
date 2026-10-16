# bootstrap-state

Creates one Cloud Storage bucket per client project for OpenTofu state.

- Versioning is on, so each apply leaves a restorable generation.
- Uniform bucket-level access is on.
- Public access prevention is `enforced`.
- A lifecycle rule deletes noncurrent versions after `noncurrent_version_retention_days` (default 90).
- A second rule deletes archived versions once `noncurrent_versions_to_keep` newer versions exist (default 30).
- `force_destroy` is false.

Plan members get `roles/storage.objectViewer` and `roles/storage.legacyBucketReader` on this bucket. Together those predefined roles allow a read of the state object and the bucket metadata. They do not allow writing the lock, so plan uses `-lock=false`. Apply members get `roles/storage.admin` on this bucket only.

Use a distinct prefix per stack inside the one client bucket.

## Backend config

Copy this into the client root as `backend.tf` after the bucket exists. Do not commit a copy that still says `REPLACE_CLIENT_STATE_BUCKET`.

```hcl
terraform {
  backend "gcs" {
    bucket = "REPLACE_CLIENT_STATE_BUCKET"
    prefix = "stacks/REPLACE_STACK_NAME"
  }
}
```

Partial configuration, when the bucket name should stay out of the root module:

```hcl
terraform {
  backend "gcs" {}
}
```

```hcl
# backend.hcl, not committed when it contains a client-specific name you would rather inject
bucket = "REPLACE_CLIENT_STATE_BUCKET"
prefix = "stacks/REPLACE_STACK_NAME"
```

```bash
tofu init -backend-config=backend.hcl
```

## Example

```hcl
module "state" {
  source = "../../modules/bootstrap-state"

  project_id  = module.project.project_id
  bucket_name = "example-client-tfstate"
  location    = "us-central1"
  plan_members = [
    module.identity.plan_member,
  ]
  apply_members = [
    module.identity.apply_member,
  ]
  labels = {
    client = "example-client"
  }
}
```

## Validate

```bash
tofu init -backend=false
tofu validate
```
