variable "name" {
  description = "Name for the recorder, delivery channel, role and rule prefix"
  type        = string
  default     = "default"
}

variable "role_arn" {
  description = "Existing IAM role for Config. Null creates one with AWS_ConfigRole and write access to the bucket"
  type        = string
  default     = null
}

variable "include_global_resources" {
  description = "Record IAM and other global resources and run the IAM rules. Turn on in one region only"
  type        = bool
  default     = true
}

variable "recording_frequency" {
  description = "CONTINUOUS or DAILY"
  type        = string
  default     = "CONTINUOUS"

  validation {
    condition     = contains(["CONTINUOUS", "DAILY"], var.recording_frequency)
    error_message = "recording_frequency must be CONTINUOUS or DAILY"
  }
}

variable "snapshot_frequency" {
  description = "How often Config delivers a configuration snapshot: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours"
  type        = string
  default     = "TwentyFour_Hours"
}

variable "s3_bucket_name" {
  description = "Existing bucket for Config history and snapshots. Null creates one. The policy of an existing bucket is up to you"
  type        = string
  default     = null
}

variable "bucket_name" {
  description = "Name for the bucket this module creates. Defaults to <name>-config-<account id>"
  type        = string
  default     = null
}

variable "s3_key_prefix" {
  description = "Prefix for objects in the bucket"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Let Terraform delete the bucket with objects in it"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Delete objects from the bucket after this many days. Null keeps them forever"
  type        = number
  default     = 2555
}

variable "kms_key_arn" {
  description = "KMS key for the bucket and delivered objects. The key policy must let the Config role use it"
  type        = string
  default     = null
}

variable "sns_topic_arn" {
  description = "SNS topic for configuration and compliance change notifications"
  type        = string
  default     = null
}

variable "default_rules_enabled" {
  description = "Create the built-in set of SOC2-related managed rules (see rules.tf)"
  type        = bool
  default     = true
}

variable "rules_disabled" {
  description = "Keys of default rules to skip, e.g. [\"alb-http-to-https\"]"
  type        = list(string)
  default     = []
}

variable "rules" {
  description = "Extra AWS managed rules keyed by a static name. identifier is the managed rule ID, e.g. EKS_SECRETS_ENCRYPTED"
  type = map(object({
    identifier       = string
    input_parameters = optional(map(string), {})
    resource_types   = optional(list(string), [])
  }))
  default = {}
}

variable "conformance_packs" {
  description = "Conformance packs keyed by pack name, from a template body or S3 URI"
  type = map(object({
    template_body   = optional(string)
    template_s3_uri = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
