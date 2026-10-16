variable "project_id" {
  type        = string
  description = "Project that will own the Cloud SQL instance and, when managed here, the Private Service Access range."
}

variable "region" {
  type        = string
  description = "Region for the Cloud SQL instance."
}

variable "name" {
  type        = string
  description = "Cloud SQL instance name."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,96}[a-z0-9]$", var.name))
    error_message = "name must be a valid Cloud SQL instance id."
  }
}

variable "network_self_link" {
  type        = string
  description = "Self link of the VPC that will reach the instance over Private Service Access."
}

variable "database_version" {
  type        = string
  description = "Cloud SQL database version. The example uses PostgreSQL."
  default     = "POSTGRES_16"
}

variable "tier" {
  type        = string
  description = "Cloud SQL machine tier."
  default     = "db-custom-1-3840"
}

variable "disk_size_gb" {
  type        = number
  description = "Initial disk size in GB. Disk autoresize is on and capped by disk_autoresize_limit_gb."
  default     = 20
}

variable "disk_autoresize_limit_gb" {
  type        = number
  description = "Upper bound in GB for disk autoresize. Zero means no cap."
  default     = 100
}

variable "availability_type" {
  type        = string
  description = "ZONAL or REGIONAL. REGIONAL is a failover replica in another zone."
  default     = "ZONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "availability_type must be ZONAL or REGIONAL."
  }
}

variable "deletion_protection" {
  type        = bool
  description = "When true, OpenTofu refuses to destroy the instance."
  default     = true
}

variable "point_in_time_recovery_enabled" {
  type        = bool
  description = "Enable point-in-time recovery. Backups themselves cannot be turned off by this module. PITR is supported on PostgreSQL and SQL Server."
  default     = true
}

variable "backup_retained_count" {
  type        = number
  description = "Number of automated backups to retain."
  default     = 14
}

variable "transaction_log_retention_days" {
  type        = number
  description = "Days of transaction logs retained for point-in-time recovery."
  default     = 7
}

variable "database_name" {
  type        = string
  description = "Optional database to create on the instance. No user or password is created."
  default     = null
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the instance."
  default     = {}
}

variable "manage_private_service_access" {
  type        = bool
  description = "Reserve a Private Service Access range and peer the VPC to servicenetworking.googleapis.com. Additional instances on the same VPC set this to false and pass allocated_ip_range."
  default     = true
}

variable "psa_prefix_length" {
  type        = number
  description = "Prefix length of the reserved Private Service Access range."
  default     = 16
}

variable "allocated_ip_range" {
  type        = string
  description = "Name of an existing allocated Private Service Access range. Leave null when this module creates the range."
  default     = null
}
