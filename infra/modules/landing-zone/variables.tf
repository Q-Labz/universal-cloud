variable "parent" {
  type        = string
  description = "Folder or organization that owns the client folder. Use folders/123 or organizations/123."

  validation {
    condition     = can(regex("^(folders|organizations)/[0-9]+$", var.parent))
    error_message = "parent must look like folders/123 or organizations/123."
  }
}

variable "client_display_name" {
  type        = string
  description = "Display name of the client folder. This is the human label in the GCP console, not a project ID."

  validation {
    condition     = length(var.client_display_name) >= 1 && length(var.client_display_name) <= 30
    error_message = "client_display_name must be 1 to 30 characters."
  }
}

variable "environments" {
  type        = set(string)
  description = "Environment subfolders created under the client folder, for example prod and nonprod."
  default     = ["nonprod", "prod"]

  validation {
    condition = alltrue([
      for name in var.environments : can(regex("^[a-z][a-z0-9-]{0,28}[a-z0-9]$", name)) || can(regex("^[a-z]$", name))
    ])
    error_message = "Environment names must be lowercase letters, digits, and hyphens."
  }
}
