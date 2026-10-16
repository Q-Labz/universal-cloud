variable "project_id" {
  type        = string
  description = "Project that will own the instances and their runtime service accounts."
}

variable "name_prefix" {
  type        = string
  description = "Prefix used for instance and service account names."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,20}$", var.name_prefix))
    error_message = "name_prefix must start with a letter and use lowercase letters, digits, and hyphens."
  }
}

variable "instances" {
  type = map(object({
    zone               = string
    machine_type       = optional(string, "n2-standard-2")
    subnetwork         = string
    image              = optional(string, "debian-cloud/debian-12")
    boot_disk_size_gb  = optional(number, 20)
    boot_disk_type     = optional(string, "pd-balanced")
    tags               = optional(list(string), [])
    labels             = optional(map(string), {})
    assign_external_ip = optional(bool, false)
  }))
  description = "Instances keyed by a short name. Shielded VM and OS Login are always on. External IP defaults off. Use an N2 (or other Shielded-VM-capable) machine type; E2 does not support Shielded VM."
}

variable "labels" {
  type        = map(string)
  description = "Labels merged onto every instance. Per-instance labels win on key collision."
  default     = {}
}
