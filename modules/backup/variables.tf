variable "name" {
  description = "Name for the vault, plan, selection and role"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for the vault. Null uses the AWS managed backup key"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Let Terraform delete the vault with recovery points in it. Doesn't work once a vault lock is active"
  type        = bool
  default     = false
}

variable "vault_lock" {
  description = "Vault Lock. With changeable_for_days set it becomes COMPLIANCE mode and can't be removed after that many days (min 3). Null means no lock"
  type = object({
    min_retention_days  = optional(number, 7)
    max_retention_days  = optional(number)
    changeable_for_days = optional(number)
  })
  default = null
}

variable "rules" {
  description = "Backup rules keyed by rule name. schedule is a cron() expression, delete_after in days. copy_to sends copies to another vault (other region/account) for DR"
  type = map(object({
    schedule           = string
    timezone           = optional(string, "UTC")
    start_window       = optional(number, 60)
    completion_window  = optional(number, 360)
    delete_after       = number
    cold_storage_after = optional(number)
    continuous_backup  = optional(bool, false)
    copy_to = optional(map(object({
      vault_arn          = string
      delete_after       = optional(number)
      cold_storage_after = optional(number)
    })), {})
  }))
  default = {
    daily = {
      schedule     = "cron(0 3 * * ? *)"
      delete_after = 35
    }
    monthly = {
      schedule           = "cron(0 4 1 * ? *)"
      delete_after       = 365
      cold_storage_after = 30
    }
  }
}

variable "windows_vss" {
  description = "Take application-consistent (VSS) backups of Windows EC2 instances"
  type        = bool
  default     = false
}

variable "role_arn" {
  description = "Existing IAM role for AWS Backup. Null creates one with the AWS managed backup/restore policies"
  type        = string
  default     = null
}

variable "selection_tag" {
  description = "Back up resources with this tag. Set to null to only use resource_arns"
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "Backup"
    value = "true"
  }
}

variable "resource_arns" {
  description = "Resources to back up, keyed by a static name. Combined with selection_tag both have to match"
  type        = map(string)
  default     = {}
}

variable "notifications" {
  description = "Send failed backup, copy and restore jobs to an SNS topic (must allow events.amazonaws.com to publish). Null turns it off"
  type = object({
    sns_topic_arn = string
  })
  default = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
