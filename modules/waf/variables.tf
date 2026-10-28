variable "name" {
  description = "Name of the web ACL, also used for metrics and the log group"
  type        = string
}

variable "description" {
  description = "Description of the web ACL"
  type        = string
  default     = "Managed by Terraform"
}

variable "scope" {
  description = "REGIONAL (ALB, API Gateway) or CLOUDFRONT. CLOUDFRONT needs a provider in us-east-1"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT"
  }
}

variable "default_action" {
  description = "allow or block requests that don't match a rule"
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "default_action must be allow or block"
  }
}

variable "managed_rule_groups" {
  description = "Managed rule groups keyed by rule name. count_only puts the whole group in count mode, excluded_rules counts single rules"
  type = map(object({
    name           = string
    priority       = number
    vendor_name    = optional(string, "AWS")
    version        = optional(string)
    count_only     = optional(bool, false)
    excluded_rules = optional(list(string), [])
  }))
  default = {
    common = {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 1
    }
    known-bad-inputs = {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 2
    }
    ip-reputation = {
      name     = "AWSManagedRulesAmazonIpReputationList"
      priority = 3
    }
  }
}

variable "blocked_ip_cidrs" {
  description = "IPv4 CIDRs to always block"
  type        = list(string)
  default     = []
}

variable "rate_limit" {
  description = "Max requests per IP in rate_limit_window_sec before blocking. Null turns it off"
  type        = number
  default     = 2000
}

variable "rate_limit_window_sec" {
  description = "Rate limit window, 60, 120, 300 or 600 seconds"
  type        = number
  default     = 300
}

variable "resource_arns" {
  description = "Regional resources (ALB, API Gateway stage) to protect, keyed by a static name. Ignored for CLOUDFRONT"
  type        = map(string)
  default     = {}
}

variable "enable_logging" {
  description = "Send WAF logs to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention for the log group"
  type        = number
  default     = 30
}

variable "log_kms_key_arn" {
  description = "KMS key for the log group (key policy must allow CloudWatch Logs)"
  type        = string
  default     = null
}

variable "redacted_headers" {
  description = "Headers to keep out of the logs, lowercase"
  type        = list(string)
  default     = ["authorization", "cookie"]
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
