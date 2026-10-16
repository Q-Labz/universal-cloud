output "sink_name" {
  description = "Logging sink name."
  value       = var.scope == "project" ? google_logging_project_sink.this[0].name : google_logging_folder_sink.this[0].name
}

output "destination" {
  description = "Sink destination URI."
  value       = local.sink_destination
}

output "writer_identity" {
  description = "Unique writer identity granted permission to write to the destination."
  value       = local.writer_identity
}

output "bucket_name" {
  description = "Log bucket name, or null when the destination is BigQuery."
  value       = try(google_storage_bucket.logs[0].name, null)
}

output "dataset_id" {
  description = "BigQuery dataset id, or null when the destination is a bucket."
  value       = try(google_bigquery_dataset.logs[0].dataset_id, null)
}
