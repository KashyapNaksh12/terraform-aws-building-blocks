variable "name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "hash_key" {
  description = "Partition key attribute name"
  type        = string
}

variable "range_key" {
  description = "Sort key attribute name (optional)"
  type        = string
  default     = null
}

variable "attributes" {
  description = "Key attributes for the table and its indexes (type S, N or B)"
  type = list(object({
    name = string
    type = string
  }))
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST (on-demand) or PROVISIONED"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  description = "Read capacity units (PROVISIONED only)"
  type        = number
  default     = null
}

variable "write_capacity" {
  description = "Write capacity units (PROVISIONED only)"
  type        = number
  default     = null
}

variable "global_secondary_indexes" {
  description = "Global secondary indexes"
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = optional(string, "ALL")
    non_key_attributes = optional(list(string))
    read_capacity      = optional(number)
    write_capacity     = optional(number)
  }))
  default = []
}

variable "ttl_attribute" {
  description = "Attribute name holding the expiry epoch for TTL. Null disables TTL"
  type        = string
  default     = null
}

variable "point_in_time_recovery" {
  description = "Enable point-in-time recovery (continuous backups)"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN. Null uses the AWS-owned key"
  type        = string
  default     = null
}

variable "stream_view_type" {
  description = "Stream view type, e.g. NEW_AND_OLD_IMAGES. Null = no stream"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
