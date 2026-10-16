output "project_id" {
  description = "Example project id."
  value       = module.project.project_id
}

output "client_folder_name" {
  description = "Client folder resource name."
  value       = module.landing_zone.client_folder_name
}

output "state_bucket_name" {
  description = "State bucket name to use in the GCS backend."
  value       = module.state.bucket_name
}

output "github_workload_identity_provider" {
  description = "Provider resource name for GitHub Actions OIDC."
  value       = module.identity.github_workload_identity_provider
}

output "scalr_workload_identity_provider" {
  description = "Provider resource name for the Scalr GCP OIDC configuration."
  value       = module.identity.scalr_workload_identity_provider
}

output "plan_service_account_email" {
  description = "Plan service account email."
  value       = module.identity.plan_service_account_email
}

output "apply_service_account_email" {
  description = "Apply service account email."
  value       = module.identity.apply_service_account_email
}

output "network_self_link" {
  description = "VPC self link."
  value       = module.network.network_self_link
}

output "sql_connection_name" {
  description = "Cloud SQL connection name."
  value       = module.sql.connection_name
}

output "log_destination" {
  description = "Log sink destination."
  value       = module.logs.destination
}
