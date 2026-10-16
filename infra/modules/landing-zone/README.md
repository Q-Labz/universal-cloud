# landing-zone

Creates a client folder, one subfolder per environment, and a baseline set of organization policies on the client folder. Child projects inherit the policies.

The baseline:

- Blocks service account key creation.
- Stops the automatic Editor grant on the default Compute Engine and App Engine service accounts.
- Denies external IPv4 addresses on VM instances.
- Requires OS Login.
- Skips the default VPC when a project is created.
- Restricts Cloud SQL public IP.
- Requires uniform bucket-level access and public access prevention.

Policies use the classic boolean and list constraints (`compute.requireOsLogin`, `compute.vmExternalIpAccess`, and the others named in `main.tf`). They are inherited by every project under the client folder.

## Example

```hcl
module "landing_zone" {
  source = "../../modules/landing-zone"

  parent              = "organizations/000000000000"
  client_display_name = "example-client"
  environments        = ["nonprod", "prod"]
}
```

## Validate

```bash
tofu init -backend=false
tofu validate
```

Nothing in this module is applied by the example root. An organization policy administrator applies it once during client onboarding.
