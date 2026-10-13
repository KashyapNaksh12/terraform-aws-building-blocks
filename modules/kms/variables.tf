variable "alias" {
  description = "Alias for the key, with or without the alias/ prefix"
  type        = string
}

variable "description" {
  description = "Description of the key"
  type        = string
  default     = "Managed by Terraform"
}

variable "key_usage" {
  description = "ENCRYPT_DECRYPT, SIGN_VERIFY or GENERATE_VERIFY_MAC"
  type        = string
  default     = "ENCRYPT_DECRYPT"
}

variable "key_spec" {
  description = "Key spec, e.g. SYMMETRIC_DEFAULT, RSA_2048, ECC_NIST_P256. Rotation only works on SYMMETRIC_DEFAULT"
  type        = string
  default     = "SYMMETRIC_DEFAULT"
}

variable "multi_region" {
  description = "Create a multi-Region primary key"
  type        = bool
  default     = false
}

variable "enable_key_rotation" {
  description = "Rotate the key material automatically (symmetric keys only)"
  type        = bool
  default     = true
}

variable "rotation_period_in_days" {
  description = "Days between automatic rotations (90-2560)"
  type        = number
  default     = 365

  validation {
    condition     = var.rotation_period_in_days >= 90 && var.rotation_period_in_days <= 2560
    error_message = "rotation_period_in_days must be between 90 and 2560"
  }
}

variable "deletion_window_in_days" {
  description = "Waiting period before the key is deleted (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days must be between 7 and 30"
  }
}

variable "admin_arns" {
  description = "IAM principals that can manage the key (not use it), keyed by a static name"
  type        = map(string)
  default     = {}
}

variable "user_arns" {
  description = "IAM principals that can encrypt/decrypt with the key and create grants for AWS services, keyed by a static name"
  type        = map(string)
  default     = {}
}

variable "allow_cloudwatch_logs" {
  description = "Let CloudWatch Logs in this account and region use the key, needed for encrypted log groups"
  type        = bool
  default     = false
}

variable "service_principals" {
  description = "AWS service principals that can use the key directly, e.g. { sns = \"sns.amazonaws.com\" }. Limited to this account via aws:SourceAccount"
  type        = map(string)
  default     = {}
}

variable "policy" {
  description = "Extra key policy JSON, merged with the generated statements"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
