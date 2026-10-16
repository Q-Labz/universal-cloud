module "landing_zone" {
  source = "../../modules/landing-zone"

  parent              = var.parent
  client_display_name = var.client_display_name
  environments        = ["nonprod", "prod"]
}

module "project" {
  source = "../../modules/project-factory"

  project_name    = var.project_name
  project_id      = var.project_id
  folder_id       = module.landing_zone.environment_folder_ids["prod"]
  billing_account = var.billing_account
  labels          = var.labels
}

module "identity" {
  source = "../../modules/identity"

  project_id         = module.project.project_id
  client_id          = var.client_id
  github_repository  = var.github_repository
  scalr_account_id   = var.scalr_account_id
  folder_id          = module.landing_zone.client_folder_name
  billing_account_id = var.billing_account
}

module "state" {
  source = "../../modules/bootstrap-state"

  project_id  = module.project.project_id
  bucket_name = var.state_bucket_name
  location    = var.region
  labels      = var.labels
  plan_members = [
    module.identity.plan_member,
  ]
  apply_members = [
    module.identity.apply_member,
  ]
}

module "network" {
  source = "../../modules/network"

  project_id   = module.project.project_id
  network_name = "${var.client_id}-vpc"
  subnets = {
    app = {
      region = var.region
      cidr   = "10.16.0.0/20"
    }
  }
  egress_rules = [
    {
      name               = "allow-https"
      priority           = 1000
      protocol           = "tcp"
      ports              = ["443"]
      destination_ranges = ["0.0.0.0/0"]
    }
  ]
}

module "vm" {
  source = "../../modules/vm"

  project_id  = module.project.project_id
  name_prefix = var.client_id
  labels      = var.labels
  instances = {
    app = {
      zone         = var.zone
      machine_type = "n2-standard-2"
      subnetwork   = module.network.subnet_self_links["app"]
    }
  }
}

module "sql" {
  source = "../../modules/cloud-sql"

  project_id        = module.project.project_id
  region            = var.region
  name              = "${var.client_id}-pg"
  network_self_link = module.network.network_self_link
  database_name     = "app"
  labels            = var.labels
}

module "logs" {
  source = "../../modules/log-sinks"

  scope            = "folder"
  folder_id        = module.landing_zone.client_folder_name
  project_id       = module.project.project_id
  destination_type = "bucket"
  destination_name = var.log_bucket_name
  location         = var.region
  labels           = var.labels
}
