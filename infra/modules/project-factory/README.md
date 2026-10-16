# project-factory

Creates one client project, links a billing account, applies labels, and enables APIs. The project is created with `auto_create_network = false` and `deletion_policy = PREVENT`. API disable-on-destroy is off so removing a service from the set does not turn the API off on the next apply that drops it from state; remove an API in a deliberate follow-up.

`managed-by=opentofu` is merged into the labels unless the caller already set that key.

## Example

```hcl
module "project" {
  source = "../../modules/project-factory"

  project_name    = "Example Client"
  project_id      = "example-client-app"
  folder_id       = module.landing_zone.environment_folder_ids["prod"]
  billing_account = "000000-000000-000000"
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
