variable "scope" {
  type        = string
  description = "Where the sink is attached. project exports one project. folder exports the folder and, by default, its children."

  validation {
    condition     = contains(["project", "folder"], var.scope)
    error_message = "scope must be project or folder."
  }
}

variable "project_id" {
  type        = string
  description = "Project that owns the destination bucket or BigQuery dataset. Also the sink project when scope is project."
}

variable "folder_id" {
  type        = string
  description = "Folder resource name (folders/123) when scope is folder. Leave null for a project sink."
  default     = null
}

variable "sink_name" {
  type        = string
  description = "Logging sink name."
  default     = "central-logs"
}

variable "filter" {
  type        = string
  description = "Logging filter. The default keeps Admin Activity, System Event, and Policy Denied audit logs plus severity ERROR and above."
  default     = "log_id(\"cloudaudit.googleapis.com/activity\") OR log_id(\"cloudaudit.googleapis.com/system_event\") OR log_id(\"cloudaudit.googleapis.com/policy\") OR severity>=ERROR"
}

variable "include_children" {
  type        = bool
  description = "When scope is folder, also export logs from descendant projects and folders."
  default     = true
}

variable "destination_type" {
  type        = string
  description = "Destination kind. bucket creates a Cloud Storage bucket. bigquery creates a BigQuery dataset."

  validation {
    condition     = contains(["bucket", "bigquery"], var.destination_type)
    error_message = "destination_type must be bucket or bigquery."
  }
}

variable "destination_name" {
  type        = string
  description = "Globally unique bucket name, or a BigQuery dataset id (letters, digits, underscores)."

  validation {
    condition = (
      var.destination_type == "bucket" &&
      can(regex("^[a-z0-9][a-z0-9-_.]{1,61}[a-z0-9]$", var.destination_name))
      ) || (
      var.destination_type == "bigquery" &&
      can(regex("^[A-Za-z_][A-Za-z0-9_]{0,1023}$", var.destination_name))
    )
    error_message = "Use a DNS-style bucket name, or a BigQuery dataset id of letters, digits, and underscores."
  }
}

variable "location" {
  type        = string
  description = "Bucket or dataset location."
  default     = "US"
}

variable "retention_days" {
  type        = number
  description = "Delete log objects in the bucket after this many days. Ignored for BigQuery."
  default     = 365
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the destination bucket. BigQuery datasets do not take these labels."
  default     = {}
}
