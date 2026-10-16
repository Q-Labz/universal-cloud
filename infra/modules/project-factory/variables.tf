variable "project_name" {
  type        = string
  description = "Display name of the GCP project."
}

variable "project_id" {
  type        = string
  description = "Globally unique GCP project ID. This value is permanent."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6 to 30 characters, start with a letter, and use lowercase letters, digits, and hyphens."
  }
}

variable "folder_id" {
  type        = string
  description = "Numeric folder id that will own the project. Do not include the folders/ prefix."
}

variable "billing_account" {
  type        = string
  description = "Billing account ID to link, in the form XXXXXX-XXXXXX-XXXXXX."

  validation {
    condition     = can(regex("^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$", var.billing_account))
    error_message = "billing_account must look like XXXXXX-XXXXXX-XXXXXX."
  }
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the project. managed-by=opentofu is added when missing."
  default     = {}
}

variable "activate_apis" {
  type        = set(string)
  description = "Google APIs to enable on the project. disable_on_destroy is false so a later destroy does not turn APIs off."
  default = [
    "cloudbilling.googleapis.com",
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "orgpolicy.googleapis.com",
    "oslogin.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ]
}
