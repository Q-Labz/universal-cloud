locals {
  sink_destination = (
    var.destination_type == "bucket"
    ? "storage.googleapis.com/${var.destination_name}"
    : "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.destination_name}"
  )
  writer_identity = one(concat(
    google_logging_project_sink.this[*].writer_identity,
    google_logging_folder_sink.this[*].writer_identity,
  ))
}

resource "google_storage_bucket" "logs" {
  count = var.destination_type == "bucket" ? 1 : 0

  name                        = var.destination_name
  project                     = var.project_id
  location                    = var.location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = var.labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = var.retention_days
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    precondition {
      condition     = var.scope != "folder" || var.folder_id != null
      error_message = "folder_id is required when scope is folder."
    }
  }
}

resource "google_bigquery_dataset" "logs" {
  count = var.destination_type == "bigquery" ? 1 : 0

  dataset_id                 = var.destination_name
  project                    = var.project_id
  location                   = var.location
  delete_contents_on_destroy = false

  lifecycle {
    precondition {
      condition     = var.scope != "folder" || var.folder_id != null
      error_message = "folder_id is required when scope is folder."
    }
  }
}

resource "google_logging_project_sink" "this" {
  count = var.scope == "project" ? 1 : 0

  name                   = var.sink_name
  project                = var.project_id
  destination            = local.sink_destination
  filter                 = var.filter
  unique_writer_identity = true

  depends_on = [
    google_storage_bucket.logs,
    google_bigquery_dataset.logs,
  ]
}

resource "google_logging_folder_sink" "this" {
  count = var.scope == "folder" ? 1 : 0

  name             = var.sink_name
  folder           = var.folder_id
  destination      = local.sink_destination
  filter           = var.filter
  include_children = var.include_children

  lifecycle {
    precondition {
      condition     = var.folder_id != null
      error_message = "folder_id is required when scope is folder."
    }
  }

  depends_on = [
    google_storage_bucket.logs,
    google_bigquery_dataset.logs,
  ]
}

resource "google_storage_bucket_iam_member" "writer" {
  count = var.destination_type == "bucket" ? 1 : 0

  bucket = google_storage_bucket.logs[0].name
  role   = "roles/storage.objectCreator"
  member = local.writer_identity
}

resource "google_bigquery_dataset_iam_member" "writer" {
  count = var.destination_type == "bigquery" ? 1 : 0

  dataset_id = google_bigquery_dataset.logs[0].dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = local.writer_identity
}
