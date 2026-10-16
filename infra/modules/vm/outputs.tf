output "instance_ids" {
  description = "Map of instance key to instance id."
  value       = { for name, instance in google_compute_instance.this : name => instance.id }
}

output "instance_self_links" {
  description = "Map of instance key to instance self link."
  value       = { for name, instance in google_compute_instance.this : name => instance.self_link }
}

output "service_account_emails" {
  description = "Map of instance key to the dedicated runtime service account email. These accounts have no project roles."
  value       = { for name, account in google_service_account.vm : name => account.email }
}
