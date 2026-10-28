variable "name" {
  description = "Topic name. .fifo is added for FIFO topics"
  type        = string
}

variable "display_name" {
  description = "Display name, used as the sender for SMS and email"
  type        = string
  default     = null
}

variable "fifo_topic" {
  description = "Create a FIFO topic (only SQS FIFO queues can subscribe)"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "FIFO only, deduplicate on a hash of the message body"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key for encryption. Null leaves the topic unencrypted"
  type        = string
  default     = null
}

variable "delivery_policy" {
  description = "Delivery retry policy JSON for HTTP/S endpoints"
  type        = string
  default     = null
}

variable "publisher_service_principals" {
  description = "AWS services allowed to publish, e.g. { cw = \"cloudwatch.amazonaws.com\", events = \"events.amazonaws.com\" }. Limited to this account via aws:SourceAccount"
  type        = map(string)
  default     = {}
}

variable "policy" {
  description = "Extra topic policy JSON, merged with the generated statements"
  type        = string
  default     = null
}

variable "subscriptions" {
  description = "Subscriptions keyed by a static name. protocol is sqs, lambda, https, email etc. dlq_arn is an SQS queue for failed deliveries"
  type = map(object({
    protocol             = string
    endpoint             = string
    raw_message_delivery = optional(bool, false)
    filter_policy        = optional(string)
    filter_policy_scope  = optional(string, "MessageAttributes")
    dlq_arn              = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
