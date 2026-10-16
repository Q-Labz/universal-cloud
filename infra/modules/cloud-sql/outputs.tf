output "instance_name" {
  description = "Cloud SQL instance name."
  value       = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "Project:region:instance connection name for the Cloud SQL Auth Proxy."
  value       = google_sql_database_instance.this.connection_name
}

output "private_ip_address" {
  description = "Private IP address of the instance. Empty until the instance has been created."
  value       = google_sql_database_instance.this.private_ip_address
}

output "psa_range_name" {
  description = "Name of the Private Service Access range created by this module, or null when the caller supplied one."
  value       = try(google_compute_global_address.psa[0].name, null)
}

output "database_name" {
  description = "Database created on the instance, or null."
  value       = try(google_sql_database.this[0].name, null)
}
