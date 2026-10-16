variable "parent" {
  type        = string
  description = "Organization or folder that will own the client folder. Placeholder only."
  default     = "organizations/000000000000"
}

variable "client_display_name" {
  type        = string
  description = "Display name of the client folder."
  default     = "example-client"
}

variable "client_id" {
  type        = string
  description = "Short client id used in resource names and service accounts."
  default     = "example-client"
}

variable "project_name" {
  type        = string
  description = "Display name of the example project."
  default     = "Example Client"
}

variable "project_id" {
  type        = string
  description = "Placeholder project id. Replace this before any real apply."
  default     = "example-client-app"
}

variable "billing_account" {
  type        = string
  description = "Placeholder billing account id. Replace this before any real apply."
  default     = "000000-000000-000000"
}

variable "region" {
  type        = string
  description = "Region for regional resources."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "Zone for the example VM."
  default     = "us-central1-a"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository locked into the workload identity provider."
  default     = "Q-Labz/universal-cloud"
}

variable "scalr_account_id" {
  type        = string
  description = "Placeholder Scalr account id locked into the workload identity provider."
  default     = "acc-exampleplaceholder"
}

variable "state_bucket_name" {
  type        = string
  description = "Placeholder state bucket name. Bucket names are global; replace this before any real apply."
  default     = "example-client-tfstate-placeholder"
}

variable "log_bucket_name" {
  type        = string
  description = "Placeholder log bucket name. Replace this before any real apply."
  default     = "example-client-logs-placeholder"
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the example project and workloads."
  default = {
    client      = "example-client"
    environment = "prod"
    service     = "cloud-ops"
  }
}
