# log-sinks

Creates a project or folder log sink and its destination.

- `destination_type = "bucket"` creates a versioned bucket with uniform bucket-level access, public access prevention, and an age-based delete rule. The sink writer receives `roles/storage.objectCreator` on that bucket.
- `destination_type = "bigquery"` creates a dataset. The sink writer receives `roles/bigquery.dataEditor` on that dataset.

A project sink sets `unique_writer_identity` so the writer is a service agent that can publish into a destination in the same project. A folder sink does not have that argument in provider 8.7.0; the module grants whatever `writer_identity` GCP returns. The default filter exports Admin Activity, System Event, and Policy Denied audit logs, plus entries at severity ERROR and above. Set `filter` to `""` only when you have accepted the cost of exporting every log.

A folder sink includes children unless `include_children` is false.

## Example

```hcl
module "logs" {
  source = "../../modules/log-sinks"

  scope            = "folder"
  folder_id        = module.landing_zone.client_folder_name
  project_id       = module.project.project_id
  destination_type = "bucket"
  destination_name = "example-client-logs"
  location         = "us-central1"
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
