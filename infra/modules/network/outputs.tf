output "network_name" {
  description = "Name of the VPC."
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "Self link of the VPC. Pass this to the Cloud SQL module."
  value       = google_compute_network.this.self_link
}

output "network_id" {
  description = "ID of the VPC."
  value       = google_compute_network.this.id
}

output "subnet_self_links" {
  description = "Map of subnet name to subnet self link."
  value       = { for name, subnet in google_compute_subnetwork.this : name => subnet.self_link }
}

output "subnet_ids" {
  description = "Map of subnet name to subnet id."
  value       = { for name, subnet in google_compute_subnetwork.this : name => subnet.id }
}
