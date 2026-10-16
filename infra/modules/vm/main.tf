locals {
  runtime_account_ids = {
    for name in keys(var.instances) : name => trimsuffix(substr(replace("${var.name_prefix}-${name}-vm", "_", "-"), 0, 30), "-")
  }
}

resource "google_service_account" "vm" {
  for_each = var.instances

  project      = var.project_id
  account_id   = local.runtime_account_ids[each.key]
  display_name = "Runtime service account for ${each.key}"
  description  = "Dedicated runtime identity. No project roles are granted by this module."
}

resource "google_compute_instance" "this" {
  for_each = var.instances

  name                      = substr("${var.name_prefix}-${each.key}", 0, 63)
  project                   = var.project_id
  zone                      = each.value.zone
  machine_type              = each.value.machine_type
  tags                      = distinct(concat(each.value.tags, ["allow-iap-ssh"]))
  labels                    = merge(var.labels, each.value.labels)
  allow_stopping_for_update = true
  can_ip_forward            = false

  boot_disk {
    initialize_params {
      image = each.value.image
      size  = each.value.boot_disk_size_gb
      type  = each.value.boot_disk_type
    }
  }

  network_interface {
    subnetwork = each.value.subnetwork

    dynamic "access_config" {
      for_each = each.value.assign_external_ip ? [1] : []
      content {}
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
  }

  service_account {
    email  = google_service_account.vm[each.key].email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
}
