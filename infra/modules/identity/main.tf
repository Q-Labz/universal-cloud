resource "google_iam_workload_identity_pool" "this" {
  project                   = var.project_id
  workload_identity_pool_id = "${var.client_id}-wif"
  display_name              = "${var.client_id} CI"
  description               = "Federation pool for GitHub Actions and the Scalr agent. No service account keys."
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "GitHub Actions"
  description                        = "OIDC provider locked to one repository in the Q-Labz organization."
  attribute_condition                = "assertion.repository_owner == \"Q-Labz\" && assertion.repository == \"${var.github_repository}\""

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
    "attribute.workflow"         = "assertion.workflow"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_iam_workload_identity_pool_provider" "scalr" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = "scalr-agent"
  display_name                       = "Scalr"
  description                        = "OIDC provider for the Scalr agent, locked to one Scalr account id."
  attribute_condition                = "assertion.scalr_account_id == \"${var.scalr_account_id}\""

  attribute_mapping = {
    "google.subject"                   = "assertion.sub"
    "attribute.aud"                    = "assertion.aud"
    "attribute.scalr_run_phase"        = "assertion.scalr_run_phase"
    "attribute.scalr_workspace_id"     = "assertion.scalr_workspace_id"
    "attribute.scalr_workspace_name"   = "assertion.scalr_workspace_name"
    "attribute.scalr_environment_id"   = "assertion.scalr_environment_id"
    "attribute.scalr_environment_name" = "assertion.scalr_environment_name"
    "attribute.scalr_account_id"       = "assertion.scalr_account_id"
    "attribute.scalr_account_name"     = "assertion.scalr_account_name"
    "attribute.scalr_run_id"           = "assertion.scalr_run_id"
    "attribute.scalr_tags"             = "assertion.scalr_tags"
  }

  oidc {
    issuer_uri = "https://scalr.io"
  }
}

resource "google_service_account" "plan" {
  project      = var.project_id
  account_id   = "${var.client_id}-plan"
  display_name = "${var.client_id} plan"
  description  = "Read-only OpenTofu plan identity. Key creation is not managed here."
}

resource "google_service_account" "apply" {
  project      = var.project_id
  account_id   = "${var.client_id}-apply"
  display_name = "${var.client_id} apply"
  description  = "Least-privilege OpenTofu apply identity. Key creation is not managed here."
}

resource "google_project_iam_member" "plan" {
  for_each = var.plan_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.plan.email}"
}

resource "google_project_iam_member" "apply" {
  for_each = var.apply_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.apply.email}"
}

resource "google_folder_iam_member" "plan" {
  for_each = var.folder_id == null ? toset([]) : var.folder_plan_roles

  folder = var.folder_id
  role   = each.value
  member = "serviceAccount:${google_service_account.plan.email}"
}

resource "google_folder_iam_member" "apply" {
  for_each = var.folder_id == null ? toset([]) : var.folder_apply_roles

  folder = var.folder_id
  role   = each.value
  member = "serviceAccount:${google_service_account.apply.email}"
}

resource "google_billing_account_iam_member" "plan" {
  count = var.billing_account_id == null ? 0 : 1

  billing_account_id = var.billing_account_id
  role               = "roles/billing.viewer"
  member             = "serviceAccount:${google_service_account.plan.email}"
}

resource "google_billing_account_iam_member" "apply" {
  count = var.billing_account_id == null ? 0 : 1

  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.apply.email}"
}

resource "google_service_account_iam_member" "github_plan" {
  service_account_id = google_service_account.plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.this.name}/attribute.repository/${var.github_repository}"
}

resource "google_service_account_iam_member" "github_apply" {
  service_account_id = google_service_account.apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.this.name}/subject/repo:${var.github_repository}:ref:refs/heads/main"
}

resource "google_service_account_iam_member" "scalr_plan" {
  service_account_id = google_service_account.plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.this.name}/attribute.scalr_account_id/${var.scalr_account_id}"

  condition {
    title       = "scalr-plan-phase"
    description = "Scalr may assume the plan service account only during the plan phase."
    expression  = "attribute.scalr_run_phase == 'plan'"
  }
}

resource "google_service_account_iam_member" "scalr_apply" {
  service_account_id = google_service_account.apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.this.name}/attribute.scalr_account_id/${var.scalr_account_id}"

  condition {
    title       = "scalr-apply-phase"
    description = "Scalr may assume the apply service account only during the apply phase."
    expression  = "attribute.scalr_run_phase == 'apply'"
  }
}
