locals {
  labels = merge(
    {
      managed-by = "opentofu"
    },
    var.labels,
  )
}

resource "google_project" "this" {
  name                = var.project_name
  project_id          = var.project_id
  folder_id           = var.folder_id
  auto_create_network = false
  deletion_policy     = "PREVENT"
  labels              = local.labels
}

resource "google_billing_project_info" "link" {
  project         = google_project.this.project_id
  billing_account = var.billing_account
}

resource "google_project_service" "this" {
  for_each = var.activate_apis

  project                    = google_project.this.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false

  depends_on = [google_billing_project_info.link]
}
