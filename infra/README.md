# 7Labz Cloud Ops, Phase 0

OpenTofu foundation for the managed GCP service. This tree is independent of the TypeScript control plane. Nothing here is applied.

| Path | Purpose |
| --- | --- |
| `modules/landing-zone` | Client folder, environment folders, baseline organization policies |
| `modules/project-factory` | Project, billing link, labels, API enablement |
| `modules/network` | Custom VPC, subnets, Cloud NAT, default-deny firewall plus explicit allows |
| `modules/vm` | Shielded VM, OS Login, no external IP by default |
| `modules/cloud-sql` | Private-IP Cloud SQL through Private Service Access, backups on |
| `modules/log-sinks` | Project or folder sink to a bucket or BigQuery |
| `modules/bootstrap-state` | One versioned state bucket per client project |
| `modules/identity` | Workload Identity Federation, plan and apply service accounts |
| `live/example-client` | Example composition with placeholder ids |
| `ci/` | Offline validate and the privileged-IAM check |

Provider `hashicorp/google` is pinned to `8.7.0` in every module. OpenTofu `1.13.1` is the version the GitHub Actions workflow installs. Module `required_version` accepts `>= 1.8.0, < 2.0.0`.

```bash
./infra/ci/validate-offline.sh
```

That command runs `tofu init -backend=false` and `tofu validate`. It does not plan or apply, and it does not call a GCP API.

Operations before a dashboard exists are in [docs/runbook.md](../docs/runbook.md). Scalr's OpenTofu support and the agent setup are in [docs/scalr.md](../docs/scalr.md).
