# example-client

Composition of the Phase 0 modules with placeholder organization, folder, billing, and project ids. This root is a template. It is not applied.

`backend.tf` is intentionally absent. `tofu init -backend=false` works offline. Copy `backend.tf.example` to `backend.tf` only when onboarding a real client, and only after the state bucket exists.

## What it composes

1. Landing zone folder, `nonprod` and `prod` subfolders, and the baseline organization policies.
2. A project in the `prod` folder, with a billing link and the default API set.
3. Workload identity, plan and apply service accounts.
4. One versioned state bucket, with read access for plan and bucket admin for apply.
5. A custom VPC, subnet, Cloud NAT, and the default-deny firewall plus an explicit HTTPS egress rule.
6. One Shielded VM without an external IP.
7. One private-IP Cloud SQL PostgreSQL instance.
8. A folder log sink into a locked-down bucket.

## Validate

From this directory:

```bash
tofu init -backend=false
tofu validate
```

Do not run `tofu apply` here. Do not point this root at a real organization.
