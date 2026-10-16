variable "project_id" {
  type        = string
  description = "Client project that will own this state bucket. Create one bucket per client project."
}

variable "bucket_name" {
  type        = string
  description = "Globally unique bucket name for this client's OpenTofu state."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-_.]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be a valid Cloud Storage bucket name."
  }
}

variable "location" {
  type        = string
  description = "Bucket location. Use a region close to the client workloads."
  default     = "US"
}

variable "noncurrent_versions_to_keep" {
  type        = number
  description = "Delete archived (noncurrent) object versions once this many newer versions exist."
  default     = 30
}

variable "noncurrent_version_retention_days" {
  type        = number
  description = "Delete a noncurrent object version this many days after it became noncurrent."
  default     = 90
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the state bucket."
  default     = {}
}

variable "plan_members" {
  type        = set(string)
  description = "IAM members granted read-only access to the state bucket. Plan runs use -lock=false so they do not need write access."
  default     = []
}

variable "apply_members" {
  type        = set(string)
  description = "IAM members granted roles/storage.admin on this bucket only, so apply can write state and take the lock."
  default     = []
}
