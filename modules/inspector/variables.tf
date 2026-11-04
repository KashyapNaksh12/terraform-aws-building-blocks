variable "name" {
  description = "Prefix for the EventBridge rule"
  type        = string
  default     = "default"
}

variable "resource_types" {
  description = "What to scan: EC2, ECR, LAMBDA, LAMBDA_CODE"
  type        = list(string)
  default     = ["EC2", "ECR", "LAMBDA"]

  validation {
    condition     = alltrue([for t in var.resource_types : contains(["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"], t)])
    error_message = "resource_types can only contain EC2, ECR, LAMBDA and LAMBDA_CODE"
  }
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
