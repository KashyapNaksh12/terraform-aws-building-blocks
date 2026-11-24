variable "name" {
  description = "Log group name, commonly prefixed with /aws/"
  type        = string
}

variable "retention_in_days" {
  description = "Number of days to retain events. Null keeps events indefinitely"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "ARN of a KMS key used to encrypt log data"
  type        = string
  default     = null
}

variable "skip_destroy" {
  description = "Retain the log group when Terraform destroys it"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the log group"
  type        = map(string)
  default     = {}
}
