# vm

Creates Compute Engine instances with:

- No external IP unless `assign_external_ip` is set on that instance. The landing-zone organization policy denies external IPv4 even if the flag is flipped, until an administrator changes the policy.
- OS Login enabled and project-wide SSH keys blocked, in instance metadata.
- Shielded VM: Secure Boot, vTPM, and integrity monitoring. The default machine type is `n2-standard-2` because E2 does not support Shielded VM.
- A dedicated runtime service account with no project roles, so the instance does not use the default Compute Engine service account.
- The `allow-iap-ssh` network tag so the network module's IAP rule can reach it.

Adding a VM is a new key in `instances`.

## Example

```hcl
module "vm" {
  source = "../../modules/vm"

  project_id  = module.project.project_id
  name_prefix = "example-client"
  labels = {
    client      = "example-client"
    environment = "prod"
  }
  instances = {
    app = {
      zone         = "us-central1-a"
      machine_type = "n2-standard-2"
      subnetwork   = module.network.subnet_self_links["app"]
    }
  }
}
```

## Validate

```bash
tofu init -backend=false
tofu validate
```
