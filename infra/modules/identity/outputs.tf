output "pool_name" {
  description = "Full resource name of the workload identity pool."
  value       = google_iam_workload_identity_pool.this.name
}

output "github_workload_identity_provider" {
  description = "Full resource name of the GitHub Actions provider. Use this as the GitHub Actions workload_identity_provider value."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "scalr_workload_identity_provider" {
  description = "Full resource name of the Scalr provider. Use this as workload_provider_name in the Scalr GCP OIDC provider configuration."
  value       = google_iam_workload_identity_pool_provider.scalr.name
}

output "plan_service_account_email" {
  description = "Plan service account email."
  value       = google_service_account.plan.email
}

output "apply_service_account_email" {
  description = "Apply service account email."
  value       = google_service_account.apply.email
}

output "plan_member" {
  description = "IAM member string for the plan service account."
  value       = "serviceAccount:${google_service_account.plan.email}"
}

output "apply_member" {
  description = "IAM member string for the apply service account."
  value       = "serviceAccount:${google_service_account.apply.email}"
}
