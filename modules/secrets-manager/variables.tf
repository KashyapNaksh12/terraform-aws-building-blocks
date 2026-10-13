variable "name" {
  description = "Name of the secret. Mutually exclusive with name_prefix"
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Name prefix, AWS adds a unique suffix. Mutually exclusive with name"
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the secret"
  type        = string
  default     = "Managed by Terraform"
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN. Null uses the AWS-managed aws/secretsmanager key"
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Days before a deleted secret is gone for good (7-30), or 0 to delete immediately"
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "recovery_window_in_days must be 0 or between 7 and 30"
  }
}

variable "create_value" {
  description = "Create a secret version from secret_string. False leaves the secret empty for someone else to fill"
  type        = bool
  default     = false
}

variable "secret_string" {
  description = "Secret value, plain text or jsonencode(...). Ends up in state"
  type        = string
  default     = null
  sensitive   = true
}

variable "ignore_value_changes" {
  description = "Only set the value on create and ignore later changes (for rotated or app-managed values)"
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "Lambda that rotates the secret. Null disables rotation"
  type        = string
  default     = null
}

variable "rotation_days" {
  description = "Rotate every N days (used when rotation_schedule_expression is null)"
  type        = number
  default     = 30
}

variable "rotation_schedule_expression" {
  description = "rate() or cron() expression for rotation, overrides rotation_days"
  type        = string
  default     = null
}

variable "replica_regions" {
  description = "Regions to replicate the secret to, region => KMS key ARN (null for the AWS-managed key there)"
  type        = map(string)
  default     = {}
}

variable "policy" {
  description = "Resource policy JSON for the secret (e.g. cross-account read)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
