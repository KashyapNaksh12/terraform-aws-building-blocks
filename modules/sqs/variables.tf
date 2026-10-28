variable "name" {
  description = "Queue name. .fifo is added for FIFO queues, the DLQ gets -dlq"
  type        = string
}

variable "fifo_queue" {
  description = "Create a FIFO queue (and FIFO DLQ)"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "FIFO only, deduplicate on a hash of the message body"
  type        = bool
  default     = false
}

variable "deduplication_scope" {
  description = "FIFO only, messageGroup or queue"
  type        = string
  default     = "queue"
}

variable "fifo_throughput_limit" {
  description = "FIFO only, perQueue or perMessageGroupId (high throughput mode)"
  type        = string
  default     = "perQueue"
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout. Set it to at least 6x the Lambda timeout when a Lambda consumes the queue"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "How long messages are kept (60-1209600)"
  type        = number
  default     = 345600
}

variable "max_message_size" {
  description = "Max message size in bytes (1024-262144)"
  type        = number
  default     = 262144
}

variable "delay_seconds" {
  description = "Delay before new messages become visible (0-900)"
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "Long polling wait time (0-20)"
  type        = number
  default     = 20
}

variable "create_dlq" {
  description = "Create a dead-letter queue and redrive to it"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Receives before a message is moved to the DLQ"
  type        = number
  default     = 5
}

variable "dlq_message_retention_seconds" {
  description = "How long messages are kept in the DLQ"
  type        = number
  default     = 1209600
}

variable "kms_key_arn" {
  description = "KMS key for encryption. Null uses SQS-managed SSE"
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "How long SQS reuses a data key before calling KMS again (60-86400)"
  type        = number
  default     = 300
}

variable "sns_topic_arns" {
  description = "SNS topics allowed to send to the queue, keyed by a static name"
  type        = map(string)
  default     = {}
}

variable "policy" {
  description = "Extra queue policy JSON, merged with the generated statements"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
