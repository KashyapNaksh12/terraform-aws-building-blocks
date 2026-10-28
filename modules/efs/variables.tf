variable "name" {
  description = "Name of the file system, also the creation token"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for encryption at rest. Null uses the AWS-managed aws/elasticfilesystem key"
  type        = string
  default     = null
}

variable "performance_mode" {
  description = "generalPurpose or maxIO"
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "elastic, bursting or provisioned"
  type        = string
  default     = "elastic"
}

variable "provisioned_throughput_in_mibps" {
  description = "Throughput when throughput_mode is provisioned"
  type        = number
  default     = null
}

variable "transition_to_ia" {
  description = "Move files to Infrequent Access after this, e.g. AFTER_30_DAYS. Null turns it off"
  type        = string
  default     = "AFTER_30_DAYS"
}

variable "transition_to_archive" {
  description = "Move files to Archive after this, e.g. AFTER_90_DAYS (elastic throughput only). Null turns it off"
  type        = string
  default     = null
}

variable "transition_to_primary_storage_class" {
  description = "Move files back to Standard on access, AFTER_1_ACCESS. Null turns it off"
  type        = string
  default     = "AFTER_1_ACCESS"
}

variable "enable_backup" {
  description = "Turn on AWS Backup for the file system"
  type        = bool
  default     = true
}

variable "replication_overwrite_protection" {
  description = "Stop the file system being used as a replication destination"
  type        = bool
  default     = true
}

variable "mount_target_subnet_ids" {
  description = "Subnets for mount targets, one per AZ, keyed by a static name"
  type        = map(string)
  default     = {}
}

variable "security_group_ids" {
  description = "Security groups for the mount targets (allow NFS 2049 from clients)"
  type        = list(string)
  default     = []
}

variable "access_points" {
  description = "Access points keyed by a static name. Clients get the uid/gid and are rooted at path, which is created with these owners if missing"
  type = map(object({
    path           = string
    uid            = number
    gid            = number
    secondary_gids = optional(list(number))
    permissions    = optional(string, "0755")
  }))
  default = {}
}

variable "policy" {
  description = "Extra file system policy JSON, merged with the generated statements"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
