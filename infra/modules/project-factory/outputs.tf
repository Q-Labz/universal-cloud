output "project_id" {
  description = "Project ID. Readers of this output wait until billing is linked and APIs are enabled."
  value       = google_project.this.project_id

  depends_on = [
    google_billing_project_info.link,
    google_project_service.this,
  ]
}

output "project_number" {
  description = "Project number."
  value       = google_project.this.number

  depends_on = [
    google_billing_project_info.link,
    google_project_service.this,
  ]
}

output "enabled_apis" {
  description = "APIs enabled by this module."
  value       = sort(tolist(var.activate_apis))
}
