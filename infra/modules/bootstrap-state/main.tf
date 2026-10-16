locals {
  labels = merge(
    {
      managed-by = "opentofu"
      purpose    = "opentofu-state"
    },
    var.labels,
  )
}

resource "google_storage_bucket" "state" {
  name                        = var.bucket_name
  project                     = var.project_id
  location                    = var.location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = local.labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = var.noncurrent_versions_to_keep
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      days_since_noncurrent_time = var.noncurrent_version_retention_days
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_member" "plan_object_viewer" {
  for_each = var.plan_members

  bucket = google_storage_bucket.state.name
  role   = "roles/storage.objectViewer"
  member = each.value
}

resource "google_storage_bucket_iam_member" "plan_bucket_reader" {
  for_each = var.plan_members

  bucket = google_storage_bucket.state.name
  role   = "roles/storage.legacyBucketReader"
  member = each.value
}

resource "google_storage_bucket_iam_member" "apply_admin" {
  for_each = var.apply_members

  bucket = google_storage_bucket.state.name
  role   = "roles/storage.admin"
  member = each.value
}
