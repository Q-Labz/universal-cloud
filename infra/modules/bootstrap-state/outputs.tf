output "bucket_name" {
  description = "State bucket name. Use this as the GCS backend bucket for every stack that belongs to the client."
  value       = google_storage_bucket.state.name
}

output "bucket_url" {
  description = "gs:// URL of the state bucket."
  value       = google_storage_bucket.state.url
}
