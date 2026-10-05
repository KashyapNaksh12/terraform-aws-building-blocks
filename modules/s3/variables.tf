variable "bucket_name" {
  description = "Globally unique bucket name. Mutually exclusive with bucket_prefix"
  type        = string
  default     = null
}

variable "bucket_prefix" {
  description = "Prefix for a generated unique bucket name. Used when bucket_name is null"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow Terraform to delete the bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable object versioning"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSE-KMS. Null uses SSE-S3 (AES256)"
  type        = string
  default     = null
}

variable "block_public_access" {
  description = "Enable all four S3 Block Public Access settings"
  type        = bool
  default     = true
}

variable "object_ownership" {
  description = "BucketOwnerEnforced (ACLs off), BucketOwnerPreferred or ObjectWriter"
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "enforce_tls" {
  description = "Add a bucket policy statement denying non-TLS requests"
  type        = bool
  default     = true
}

variable "policy" {
  description = "Additional bucket policy JSON to merge with the module's generated statements"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "Lifecycle rules (transitions, expiry, old version cleanup)"
  type = list(object({
    id                                 = string
    enabled                            = optional(bool, true)
    prefix                             = optional(string, "")
    expiration_days                    = optional(number)
    noncurrent_version_expiration_days = optional(number)
    abort_incomplete_multipart_days    = optional(number, 7)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default = []
}

variable "cors_rules" {
  description = "CORS rules for the bucket"
  type = list(object({
    allowed_methods = list(string)
    allowed_origins = list(string)
    allowed_headers = optional(list(string), [])
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number)
  }))
  default = []
}

variable "logging_target_bucket" {
  description = "Bucket to send server access logs to. Null disables access logging"
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "Prefix for access log objects"
  type        = string
  default     = "access-logs/"
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
