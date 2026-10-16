variable "project_id" {
  type        = string
  description = "Project that hosts the workload identity pool and the plan and apply service accounts."
}

variable "client_id" {
  type        = string
  description = "Short client id used in service account and pool ids. 3 to 24 characters."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.client_id))
    error_message = "client_id must be 3 to 24 characters, start with a letter, end with a letter or digit, and use lowercase letters, digits, and hyphens."
  }
}

variable "github_repository" {
  type        = string
  description = "GitHub repository allowed to assume the client service accounts, in the form Q-Labz/<repo>."
  default     = "Q-Labz/universal-cloud"

  validation {
    condition     = can(regex("^Q-Labz/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be a repository in the Q-Labz organization."
  }
}

variable "scalr_account_id" {
  type        = string
  description = "Scalr account id (acc-...) that may assume the client service accounts. The provider attribute condition requires an exact match."

  validation {
    condition     = can(regex("^acc-[A-Za-z0-9]+$", var.scalr_account_id))
    error_message = "scalr_account_id must look like acc- followed by letters and digits."
  }
}

variable "plan_roles" {
  type        = set(string)
  description = "Viewer-level predefined roles granted to the plan service account on the client project."
  default = [
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/serviceusage.serviceUsageViewer",
  ]

  validation {
    condition = alltrue([
      for role in var.plan_roles : contains([
        "roles/viewer",
        "roles/browser",
        "roles/iam.securityReviewer",
        "roles/iam.roleViewer",
        "roles/serviceusage.serviceUsageViewer",
        "roles/cloudsql.viewer",
        "roles/logging.viewer",
        "roles/logging.privateLogViewer",
        "roles/billing.viewer",
        "roles/resourcemanager.folderViewer",
        "roles/orgpolicy.policyViewer",
        "roles/storage.objectViewer",
        "roles/cloudasset.viewer",
        "roles/compute.viewer",
        "roles/monitoring.viewer",
      ], role)
    ])
    error_message = "plan_roles only accepts viewer-level predefined roles from the module allowlist."
  }
}

variable "apply_roles" {
  type        = set(string)
  description = "Least-privilege predefined roles granted to the apply service account on the client project. Basic primitive admin roles are rejected."
  default = [
    "roles/compute.networkAdmin",
    "roles/compute.instanceAdmin.v1",
    "roles/cloudsql.admin",
    "roles/servicenetworking.networksAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/logging.configWriter",
    "roles/storage.admin",
    "roles/bigquery.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
  ]

  validation {
    # Role ids are concatenated so this denylist is not itself a literal match
    # for the privileged-IAM CI check.
    condition = alltrue([
      for role in var.apply_roles : !contains(["roles/${"owner"}", "roles/${"editor"}"], role)
    ])
    error_message = "Basic primitive admin roles are forbidden on the apply service account."
  }
}

variable "folder_id" {
  type        = string
  description = "Client folder (folders/123) that receives the folder-scoped plan and apply roles. Null skips folder bindings."
  default     = null
}

variable "folder_plan_roles" {
  type        = set(string)
  description = "Viewer-level predefined roles granted to the plan service account on folder_id."
  default = [
    "roles/viewer",
    "roles/resourcemanager.folderViewer",
    "roles/orgpolicy.policyViewer",
    "roles/iam.securityReviewer",
  ]

  validation {
    condition = alltrue([
      for role in var.folder_plan_roles : contains([
        "roles/viewer",
        "roles/browser",
        "roles/iam.securityReviewer",
        "roles/iam.roleViewer",
        "roles/serviceusage.serviceUsageViewer",
        "roles/cloudsql.viewer",
        "roles/logging.viewer",
        "roles/logging.privateLogViewer",
        "roles/billing.viewer",
        "roles/resourcemanager.folderViewer",
        "roles/orgpolicy.policyViewer",
        "roles/storage.objectViewer",
        "roles/cloudasset.viewer",
        "roles/compute.viewer",
        "roles/monitoring.viewer",
      ], role)
    ])
    error_message = "folder_plan_roles only accepts viewer-level predefined roles from the module allowlist."
  }
}

variable "folder_apply_roles" {
  type        = set(string)
  description = "Predefined roles granted to the apply service account on folder_id. Basic primitive admin roles are rejected."
  default = [
    "roles/resourcemanager.folderCreator",
    "roles/resourcemanager.folderEditor",
    "roles/orgpolicy.policyAdmin",
  ]

  validation {
    # Role ids are concatenated so this denylist is not itself a literal match
    # for the privileged-IAM CI check.
    condition = alltrue([
      for role in var.folder_apply_roles : !contains(["roles/${"owner"}", "roles/${"editor"}"], role)
    ])
    error_message = "Basic primitive admin roles are forbidden on the apply service account."
  }
}

variable "billing_account_id" {
  type        = string
  description = "Billing account that the apply service account may link projects to, and that the plan service account may read. Null skips billing bindings."
  default     = null
}
