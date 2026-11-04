variable "name" {
  description = "Prefix for the EventBridge rule"
  type        = string
  default     = "default"
}

variable "standards" {
  description = "Standards to subscribe to, as the part after standards/ in the ARN, e.g. nist-800-53/v/5.0.0 or pci-dss/v/4.0.1"
  type        = list(string)
  default = [
    "aws-foundational-security-best-practices/v/1.0.0",
    "cis-aws-foundations-benchmark/v/3.0.0",
  ]
}

variable "disabled_controls" {
  description = "Controls to turn off, keyed by a static name. standard must be in var.standards, control_id is e.g. EC2.10, reason is shown in the console"
  type = map(object({
    standard   = string
    control_id = string
    reason     = string
  }))
  default = {}
}

variable "aggregate_regions" {
  description = "Make this region the aggregation region. [] links all regions, a list links only those. Null turns aggregation off"
  type        = list(string)
  default     = null
}

variable "notifications" {
  description = "Send new findings to an SNS topic (must allow events.amazonaws.com to publish). Null turns it off"
  type = object({
    sns_topic_arn = string
    severities    = optional(list(string), ["CRITICAL", "HIGH"])
  })
  default = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
