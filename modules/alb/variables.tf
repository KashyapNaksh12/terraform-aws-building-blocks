variable "name" {
  description = "Name of the load balancer (max 32 chars)"
  type        = string

  validation {
    condition     = length(var.name) <= 32
    error_message = "ALB name must be 32 characters or fewer"
  }
}

variable "vpc_id" {
  description = "VPC ID for the target group and security group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the ALB (public subnets for internet-facing, at least two AZs)"
  type        = list(string)
}

variable "internal" {
  description = "Create an internal (private) load balancer"
  type        = bool
  default     = false
}

variable "allowed_cidrs" {
  description = "IPv4 CIDRs allowed to reach the ALB listeners"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_security_group_ids" {
  description = "Extra security groups to attach to the ALB"
  type        = list(string)
  default     = []
}

variable "certificate_arn" {
  description = "ACM cert ARN. If set we add a 443 listener and redirect 80 to it"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "target_type" {
  description = "Target type: instance, ip, or lambda"
  type        = string
  default     = "instance"
}

variable "target_port" {
  description = "Port targets receive traffic on"
  type        = number
  default     = 80
}

variable "target_protocol" {
  description = "Protocol used to reach targets: HTTP or HTTPS"
  type        = string
  default     = "HTTP"
}

variable "health_check" {
  description = "Target group health check settings"
  type = object({
    path                = optional(string, "/")
    matcher             = optional(string, "200-399")
    interval            = optional(number, 30)
    timeout             = optional(number, 5)
    healthy_threshold   = optional(number, 3)
    unhealthy_threshold = optional(number, 3)
  })
  default = {}
}

variable "target_ids" {
  description = "Targets to register (instance IDs or IPs), keyed by a static name"
  type        = map(string)
  default     = {}
}

variable "idle_timeout" {
  description = "Idle timeout in seconds"
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs. Null disables access logs"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
