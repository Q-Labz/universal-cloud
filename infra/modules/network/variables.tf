variable "project_id" {
  type        = string
  description = "Project that will own the VPC, subnets, Cloud NAT, and firewall rules."
}

variable "network_name" {
  type        = string
  description = "Name of the custom-mode VPC."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.network_name))
    error_message = "network_name must be a valid GCP resource name."
  }
}

variable "routing_mode" {
  type        = string
  description = "VPC routing mode. GLOBAL lets subnets in different regions reach each other."
  default     = "GLOBAL"

  validation {
    condition     = contains(["GLOBAL", "REGIONAL"], var.routing_mode)
    error_message = "routing_mode must be GLOBAL or REGIONAL."
  }
}

variable "subnets" {
  type = map(object({
    region = string
    cidr   = string
  }))
  description = "Subnets keyed by name. Private Google access and VPC flow logs are always on."

  validation {
    condition     = length(var.subnets) > 0
    error_message = "Provide at least one subnet."
  }
}

variable "ingress_rules" {
  type = list(object({
    name          = string
    priority      = number
    protocol      = string
    ports         = optional(list(string), [])
    source_ranges = list(string)
    target_tags   = optional(list(string), [])
  }))
  description = "Extra explicit ingress allows. They are evaluated before the default deny. Open-world sources are rejected."
  default     = []

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      rule.priority >= 1 && rule.priority <= 65533 &&
      !contains(rule.source_ranges, "0.0.0.0/0") &&
      !contains(rule.source_ranges, "::/0") &&
      (rule.protocol != "all" || length(rule.ports) == 0)
    ])
    error_message = "Ingress rules need priority 1-65533, a specific source, and no ports when protocol is all."
  }
}

variable "egress_rules" {
  type = list(object({
    name               = string
    priority           = number
    protocol           = string
    ports              = optional(list(string), [])
    destination_ranges = list(string)
    target_tags        = optional(list(string), [])
  }))
  description = "Explicit egress allows. Internet egress is not created unless a rule here names it. A default deny covers everything else."
  default     = []

  validation {
    condition = alltrue([
      for rule in var.egress_rules :
      rule.priority >= 1 && rule.priority <= 65533 &&
      (rule.protocol != "all" || length(rule.ports) == 0)
    ])
    error_message = "Egress rules need priority 1-65533, and no ports when protocol is all."
  }
}

variable "allow_health_checks" {
  type        = bool
  description = "When true, add an explicit ingress allow from the Google Cloud health-check ranges."
  default     = false
}

variable "health_check_ports" {
  type        = list(string)
  description = "TCP ports opened to Google health-check ranges when allow_health_checks is true."
  default     = ["80", "443"]
}
