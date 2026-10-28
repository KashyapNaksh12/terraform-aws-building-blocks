variable "domain_name" {
  description = "Zone name to create, e.g. example.com. Ignored when zone_id is set"
  type        = string
  default     = null
}

variable "zone_id" {
  description = "Existing zone to add records to. Null creates a new zone"
  type        = string
  default     = null
}

variable "comment" {
  description = "Zone comment"
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_ids" {
  description = "VPCs to associate, makes it a private zone. Empty creates a public zone"
  type        = list(string)
  default     = []
}

variable "delegation_set_id" {
  description = "Reusable delegation set for the name servers (public zones only)"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Delete all records (including ones not managed here) when destroying the zone"
  type        = bool
  default     = false
}

variable "records" {
  description = "Records keyed by a static name. name is relative or full, \"@\" for the apex. Use records + ttl or alias, not both"
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = optional(list(string), [])
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, true)
    }))
    set_identifier  = optional(string)
    weight          = optional(number)
    failover        = optional(string)
    health_check_id = optional(string)
    allow_overwrite = optional(bool, false)
  }))
  default = {}
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
