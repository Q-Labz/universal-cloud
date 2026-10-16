locals {
  allocated_ip_range = coalesce(
    var.allocated_ip_range,
    try(google_compute_global_address.psa[0].name, null),
  )
}

resource "google_compute_global_address" "psa" {
  count = var.manage_private_service_access ? 1 : 0

  name          = "${var.name}-psa"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.psa_prefix_length
  network       = var.network_self_link
}

resource "google_service_networking_connection" "psa" {
  count = var.manage_private_service_access ? 1 : 0

  network                 = var.network_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa[0].name]
  deletion_policy         = "ABANDON"
}

resource "google_sql_database_instance" "this" {
  name                = var.name
  project             = var.project_id
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size_gb
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    disk_autoresize_limit = var.disk_autoresize_limit_gb
    user_labels           = var.labels

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_self_link
      allocated_ip_range                            = local.allocated_ip_range
      enable_private_path_for_google_cloud_services = true
      ssl_mode                                      = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = var.point_in_time_recovery_enabled
      start_time                     = "03:00"
      transaction_log_retention_days = var.transaction_log_retention_days

      backup_retention_settings {
        retained_backups = var.backup_retained_count
        retention_unit   = "COUNT"
      }
    }
  }

  lifecycle {
    precondition {
      condition     = local.allocated_ip_range != null
      error_message = "Enable manage_private_service_access or set allocated_ip_range. Public IP is not a supported fallback."
    }
  }

  depends_on = [google_service_networking_connection.psa]
}

resource "google_sql_database" "this" {
  count = var.database_name == null ? 0 : 1

  name     = var.database_name
  project  = var.project_id
  instance = google_sql_database_instance.this.name
}
