# universal-cloud

Multi-cloud control plane for building and managing infrastructure across **Google Cloud**, **AWS**, and **Azure** through one API and one manifest format.

Most companies are leaving physical servers for cloud. Clients rarely standardize on a single vendor. This project gives you a **provider-adapter** architecture: your product talks to a normalized model; each cloud plugs in behind the same interface.

## Why this shape

| Layer | Responsibility |
| --- | --- |
| Manifest / API | Client-facing desired state (`compute.instance`, `storage.bucket`, …) |
| Control plane | Validate, apply, track operations, store managed resources |
| Provider adapters | Translate intent → native GCP / AWS / Azure APIs |

GCP is implemented first (your immediate client need), including native request planning for Compute, Storage, VPC, Cloud SQL, and GKE. AWS and Azure ship as stubs with the same contract so you can grow per client without rewriting the core.

## Quick start

```bash
npm install
npm test
npm run cli -- providers
npm run cli -- apply examples/gcp-web-stack.yaml
npm run dev   # HTTP API on http://localhost:8787
```

Dry-run is the default. Nothing touches a real cloud project unless you opt in.

## Example: GCP client stack

```bash
npm run cli -- apply examples/gcp-web-stack.yaml
```

Manifest excerpt:

```yaml
apiVersion: universal-cloud/v1
kind: Stack
metadata:
  name: client-acme-gcp
spec:
  resources:
    - name: acme-web-1
      kind: compute.instance
      platform: gcp
      region: us-central1
      tenancy: acme-staging-123456   # GCP project ID
      spec:
        zone: us-central1-a
        machineType: e2-medium
```

## HTTP API

| Method | Path | Description |
| --- | --- |
| `GET` | `/health` | Liveness |
| `GET` | `/v1/providers` | Registered platforms + capabilities |
| `GET` | `/v1/resources` | List managed resources |
| `POST` | `/v1/resources?dryRun=true` | Apply one resource |
| `POST` | `/v1/stacks:apply?dryRun=true` | Apply a full stack manifest |
| `DELETE` | `/v1/resources/:id?dryRun=true` | Destroy |
| `GET` | `/v1/operations` | Audit trail |

## Adding a cloud or deepening GCP live mode

1. Implement `CloudProvider` in `src/providers/<platform>/`.
2. Register it in `src/bootstrap.ts`.
3. Map `ResourceKind` → native types (see `src/providers/gcp/mapper.ts`).

For real GCP mutations:

1. Install the relevant `@google-cloud/*` clients.
2. Implement `GcpProvider.executeLive`.
3. Set `UNIVERSAL_CLOUD_LIVE=1` and Application Default Credentials.
4. Call the CLI/API with `--live` / `dryRun=false`.

## Roadmap (practical order)

1. Persist state (Postgres) instead of in-memory store
2. Wire live GCP Compute + Storage with service-account auth
3. Per-client credentials vault (never store keys in git)
4. Fill AWS / Azure adapters for the same resource kinds
5. Optional Terraform/Pulumi export for teams that want IaC check-in

## License

MIT
