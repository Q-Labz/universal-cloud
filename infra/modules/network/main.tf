locals {
  subnet_cidrs = [for subnet in values(var.subnets) : subnet.cidr]
  nat_regions  = toset([for subnet in values(var.subnets) : subnet.region])
  ingress_rules = {
    for rule in var.ingress_rules : rule.name => rule
  }
  egress_rules = {
    for rule in var.egress_rules : rule.name => rule
  }
}

resource "google_compute_network" "this" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "this" {
  for_each = var.subnets

  name                     = each.key
  project                  = var.project_id
  network                  = google_compute_network.this.id
  region                   = each.value.region
  ip_cidr_range            = each.value.cidr
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "nat" {
  for_each = local.nat_regions

  name    = substr("${var.network_name}-${each.value}-router", 0, 63)
  project = var.project_id
  region  = each.value
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "nat" {
  for_each = local.nat_regions

  name                               = substr("${var.network_name}-${each.value}-nat", 0, 63)
  project                            = var.project_id
  router                             = google_compute_router.nat[each.key].name
  region                             = each.value
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "deny_all_ingress" {
  name        = substr("${var.network_name}-deny-all-ingress", 0, 63)
  project     = var.project_id
  network     = google_compute_network.this.name
  description = "Default deny for ingress. Explicit allows use a lower priority number."
  direction   = "INGRESS"
  priority    = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "deny_all_egress" {
  name        = substr("${var.network_name}-deny-all-egress", 0, 63)
  project     = var.project_id
  network     = google_compute_network.this.name
  description = "Default deny for egress. Add an explicit egress rule for any path that must leave the VPC."
  direction   = "EGRESS"
  priority    = 65534

  deny {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_internal" {
  name        = substr("${var.network_name}-allow-internal", 0, 63)
  project     = var.project_id
  network     = google_compute_network.this.name
  description = "Explicit allow for traffic between subnets in this VPC."
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = local.subnet_cidrs
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name        = substr("${var.network_name}-allow-iap-ssh", 0, 63)
  project     = var.project_id
  network     = google_compute_network.this.name
  description = "Explicit allow for SSH through Identity-Aware Proxy. Targets the allow-iap-ssh tag."
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-iap-ssh"]
}

resource "google_compute_firewall" "allow_health_checks" {
  count = var.allow_health_checks ? 1 : 0

  name        = substr("${var.network_name}-allow-health-checks", 0, 63)
  project     = var.project_id
  network     = google_compute_network.this.name
  description = "Explicit allow from Google Cloud health-check and legacy health-check ranges."
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = var.health_check_ports
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}

resource "google_compute_firewall" "ingress" {
  for_each = local.ingress_rules

  name        = each.key
  project     = var.project_id
  network     = google_compute_network.this.name
  description = "Caller-supplied explicit ingress allow."
  direction   = "INGRESS"
  priority    = each.value.priority

  allow {
    protocol = each.value.protocol
    ports    = length(each.value.ports) == 0 ? null : each.value.ports
  }

  source_ranges = each.value.source_ranges
  target_tags   = each.value.target_tags
}

resource "google_compute_firewall" "egress" {
  for_each = local.egress_rules

  name        = each.key
  project     = var.project_id
  network     = google_compute_network.this.name
  description = "Caller-supplied explicit egress allow."
  direction   = "EGRESS"
  priority    = each.value.priority

  allow {
    protocol = each.value.protocol
    ports    = length(each.value.ports) == 0 ? null : each.value.ports
  }

  destination_ranges = each.value.destination_ranges
  target_tags        = each.value.target_tags
}
