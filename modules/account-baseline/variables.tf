variable "manage_global_settings" {
  description = "Create the account-wide settings (password policy, S3 public access block, alias, contacts, support role). Set false when using the module in a second region"
  type        = bool
  default     = true
}

variable "password_policy" {
  description = "IAM password policy. Upper, lower, numbers and symbols are always required. max_age_days null means passwords don't expire. Null skips the policy"
  type = object({
    minimum_length   = optional(number, 14)
    reuse_prevention = optional(number, 24)
    max_age_days     = optional(number, 90)
  })
  default = {}
}

variable "s3_block_public_access" {
  description = "Turn on S3 Block Public Access for the whole account"
  type        = bool
  default     = true
}

variable "account_alias" {
  description = "IAM account alias for the sign-in URL"
  type        = string
  default     = null
}

variable "alternate_contacts" {
  description = "Alternate contacts keyed by type: SECURITY, OPERATIONS or BILLING"
  type = map(object({
    name  = string
    title = string
    email = string
    phone = string
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.alternate_contacts) : contains(["SECURITY", "OPERATIONS", "BILLING"], k)])
    error_message = "alternate_contacts keys must be SECURITY, OPERATIONS or BILLING"
  }
}

variable "support_role_principals" {
  description = "IAM principals that can assume an aws-support role (AWSSupportAccess, MFA required), keyed by a static name. Empty skips the role"
  type        = map(string)
  default     = {}
}

variable "ebs_encryption_by_default" {
  description = "Encrypt all new EBS volumes and snapshots in this region"
  type        = bool
  default     = true
}

variable "ebs_kms_key_arn" {
  description = "Default KMS key for EBS encryption in this region. Null uses aws/ebs"
  type        = string
  default     = null
}

variable "block_public_amis" {
  description = "Block public sharing of AMIs in this region"
  type        = bool
  default     = true
}

variable "disable_serial_console" {
  description = "Turn off EC2 serial console access in this region"
  type        = bool
  default     = true
}

variable "access_analyzer" {
  description = "IAM Access Analyzer for external access. unused_access_age (days) also creates an unused access analyzer, which is billed per role/user. Null skips it"
  type = object({
    name              = optional(string, "default")
    organization      = optional(bool, false)
    unused_access_age = optional(number)
  })
  default = {}
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
