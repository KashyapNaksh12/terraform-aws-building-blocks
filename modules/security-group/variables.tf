variable "name" {
  description = "Name of the security group"
  type        = string
}

variable "description" {
  description = "Description of the security group"
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "ID of the VPC to create the security group in"
  type        = string
}

variable "ingress_rules" {
  description = "Ingress rules keyed by name. Give each one a single source (cidr_ipv4, cidr_ipv6, prefix_list_id or referenced_security_group_id)"
  type = map(object({
    description                  = optional(string)
    ip_protocol                  = optional(string, "tcp")
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {}
}

variable "egress_rules" {
  description = "Egress rules, same format as ingress_rules. Default allows all outbound"
  type = map(object({
    description                  = optional(string)
    ip_protocol                  = optional(string, "tcp")
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {
    all_ipv4 = {
      description = "Allow all outbound IPv4"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
