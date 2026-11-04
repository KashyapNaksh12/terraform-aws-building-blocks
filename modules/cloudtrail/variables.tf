variable "name" {
  description = "Trail name, also used for the bucket, log group and alarm names"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for the trail, bucket and log group. The key policy must allow cloudtrail.amazonaws.com and CloudWatch Logs (allow_cloudwatch_logs on the kms module)"
  type        = string
  default     = null
}

variable "is_multi_region_trail" {
  description = "Log events from all regions"
  type        = bool
  default     = true
}

variable "is_organization_trail" {
  description = "Trail for every account in the organization. Must be created in the management (or delegated admin) account"
  type        = bool
  default     = false
}

variable "organization_id" {
  description = "Organization ID (o-xxxx), lets an organization trail write to the bucket"
  type        = string
  default     = null
}

variable "s3_bucket_name" {
  description = "Existing bucket to send logs to. Null creates a bucket in this module. The bucket policy of an existing bucket is up to you"
  type        = string
  default     = null
}

variable "bucket_name" {
  description = "Name for the bucket this module creates. Defaults to <name>-cloudtrail-<account id>"
  type        = string
  default     = null
}

variable "s3_key_prefix" {
  description = "Prefix for log objects in the bucket"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Let Terraform delete the bucket with logs in it. Needs deny_log_deletion = false"
  type        = bool
  default     = false
}

variable "deny_log_deletion" {
  description = "Bucket policy denies deleting log objects for everyone. Lifecycle expiry is not affected"
  type        = bool
  default     = true
}

variable "object_lock" {
  description = "Turn on S3 Object Lock with a default retention (mode GOVERNANCE or COMPLIANCE). Only works on a new bucket"
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

variable "glacier_transition_days" {
  description = "Move logs to Glacier after this many days. Null keeps them in Standard"
  type        = number
  default     = 90
}

variable "log_retention_days" {
  description = "Delete logs from the bucket after this many days. Null keeps them forever. SOC2 auditors usually want at least 365"
  type        = number
  default     = 2555

  validation {
    condition     = var.log_retention_days == null || try(var.log_retention_days >= 365, false)
    error_message = "log_retention_days should be at least 365, or null"
  }
}

variable "access_logging_bucket" {
  description = "Bucket for S3 server access logs of the trail bucket. Null turns access logging off"
  type        = string
  default     = null
}

variable "cloudwatch_logs_enabled" {
  description = "Also send the trail to a CloudWatch log group. Needed for the security alarms"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_days" {
  description = "Retention for the CloudWatch log group"
  type        = number
  default     = 365
}

variable "sns_topic_arn" {
  description = "SNS topic to notify on every log file delivery. Usually not needed"
  type        = string
  default     = null
}

variable "s3_data_events" {
  description = "Log S3 object-level events (GetObject, PutObject...) for all buckets. Can get expensive"
  type        = bool
  default     = false
}

variable "lambda_data_events" {
  description = "Log Lambda Invoke events for all functions"
  type        = bool
  default     = false
}

variable "insight_types" {
  description = "CloudTrail Insights types: ApiCallRateInsight, ApiErrorRateInsight. Extra cost"
  type        = list(string)
  default     = []
}

variable "security_alarms_enabled" {
  description = "Create the CIS metric filters and alarms (root usage, console login without MFA, IAM/SG/NACL/VPC changes...)"
  type        = bool
  default     = true
}

variable "security_alarms_disabled" {
  description = "Alarm keys to skip, e.g. [\"organizations-changes\"]. See alarms.tf for the list"
  type        = list(string)
  default     = []
}

variable "alarm_actions" {
  description = "ARNs to notify when a security alarm fires, usually an SNS topic"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
