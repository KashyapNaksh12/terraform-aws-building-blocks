variable "bucket_name" {
  description = "Name of the bucket"
  type        = string
}

variable "force_destroy" {
  description = "Let Terraform delete the bucket with objects in it"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key for default encryption. Null uses SSE-S3 (AES256)"
  type        = string
  default     = null
}

variable "object_lock" {
  description = "Turn on S3 Object Lock with a default retention (mode GOVERNANCE or COMPLIANCE). Can only be set when the bucket is created"
  type = object({
    mode = optional(string, "GOVERNANCE")
    days = number
  })
  default = null

  validation {
    condition     = var.object_lock == null || contains(["GOVERNANCE", "COMPLIANCE"], try(var.object_lock.mode, ""))
    error_message = "object_lock.mode must be GOVERNANCE or COMPLIANCE"
  }
}

variable "lifecycle_rule_id" {
  description = "ID of the lifecycle rule"
  type        = string
  default     = "retention"
}

variable "glacier_transition_days" {
  description = "Move objects to Glacier after this many days. Null keeps them in Standard"
  type        = number
  default     = null
}

variable "retention_days" {
  description = "Delete objects after this many days. Null keeps them forever"
  type        = number
  default     = null
}

variable "noncurrent_version_retention_days" {
  description = "Delete noncurrent object versions after this many days"
  type        = number
  default     = 30
}

variable "access_logging_bucket" {
  description = "Bucket for S3 server access logs of this bucket. Null turns access logging off"
  type        = string
  default     = null
}

variable "deny_object_deletion" {
  description = "Bucket policy denies deleting objects and versions for everyone. Lifecycle expiry is not affected. Needs force_destroy = false"
  type        = bool
  default     = false
}

variable "source_policy_documents" {
  description = "IAM policy documents (JSON) merged into the bucket policy, e.g. the statements that let a service write to the bucket. Sids must not clash with DenyInsecureTransport and DenyObjectDeletion"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
