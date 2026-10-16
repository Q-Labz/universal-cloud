output "client_folder_name" {
  description = "Resource name of the client folder, in the form folders/123."
  value       = google_folder.client.name
}

output "client_folder_id" {
  description = "Numeric folder id of the client folder."
  value       = google_folder.client.folder_id
}

output "environment_folder_names" {
  description = "Map of environment name to folder resource name (folders/123)."
  value       = { for name, folder in google_folder.environment : name => folder.name }
}

output "environment_folder_ids" {
  description = "Map of environment name to numeric folder id."
  value       = { for name, folder in google_folder.environment : name => folder.folder_id }
}
