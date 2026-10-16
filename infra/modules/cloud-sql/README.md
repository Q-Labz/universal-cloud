# cloud-sql

Creates a Cloud SQL instance that has no public IPv4 address. Connectivity is Private Service Access only:

- An internal global address with purpose `VPC_PEERING`.
- A `servicenetworking.googleapis.com` connection on the VPC.
- `ipv4_enabled = false`, `ssl_mode = ENCRYPTED_ONLY`, and private path for Google services.
- Automated backups, with point-in-time recovery on by default.
- Deletion protection on by default.

The module does not create a user or a password. Create an IAM database user in a later change if the engine supports it.

The first instance on a VPC should leave `manage_private_service_access` at its default. Further instances on that VPC set it to false and pass `allocated_ip_range` from the first module's `psa_range_name` output. The peering connection is abandoned on destroy so a database replacement does not tear down the VPC peering.

## Example

```hcl
module "sql" {
  source = "../../modules/cloud-sql"

  project_id        = module.project.project_id
  region            = "us-central1"
  name              = "example-client-pg"
  network_self_link = module.network.network_self_link
  database_version  = "POSTGRES_16"
  database_name     = "app"
  labels = {
    client      = "example-client"
    environment = "prod"
  }
}
```

## Validate

```bash
tofu init -backend=false
tofu validate
```
