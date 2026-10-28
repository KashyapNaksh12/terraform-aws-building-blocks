variable "name" {
  description = "Replication group ID, also used for the subnet/parameter group and log group (max 40 chars)"
  type        = string

  validation {
    condition     = length(var.name) <= 40
    error_message = "name must be 40 characters or less"
  }
}

variable "description" {
  description = "Description of the replication group"
  type        = string
  default     = "Managed by Terraform"
}

variable "engine" {
  description = "redis or valkey"
  type        = string
  default     = "valkey"

  validation {
    condition     = contains(["redis", "valkey"], var.engine)
    error_message = "engine must be redis or valkey"
  }
}

variable "engine_version" {
  description = "Engine version, e.g. 8.0 for valkey or 7.1 for redis"
  type        = string
  default     = "8.0"
}

variable "node_type" {
  description = "Node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "port" {
  description = "Port"
  type        = number
  default     = 6379
}

variable "parameter_group_family" {
  description = "Family for a new parameter group, e.g. valkey8 or redis7. Null skips it"
  type        = string
  default     = null
}

variable "parameters" {
  description = "Parameters for the new parameter group, name => value"
  type        = map(string)
  default     = {}
}

variable "parameter_group_name" {
  description = "Existing parameter group (used when parameter_group_family is null). Null uses the engine default"
  type        = string
  default     = null
}

variable "cluster_mode_enabled" {
  description = "Shard data across num_node_groups"
  type        = bool
  default     = false
}

variable "num_node_groups" {
  description = "Number of shards (cluster mode only)"
  type        = number
  default     = 1
}

variable "replicas_per_node_group" {
  description = "Replicas per shard (0-5). At least 1 turns on automatic failover"
  type        = number
  default     = 1
}

variable "multi_az_enabled" {
  description = "Fail over across AZs. Only applies when there are replicas"
  type        = bool
  default     = true
}

variable "subnet_group_name" {
  description = "Existing subnet group. Null creates one from subnet_ids"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for a new subnet group"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security groups for the nodes"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key for encryption at rest. Null uses the AWS-managed key"
  type        = string
  default     = null
}

variable "auth_token" {
  description = "AUTH token (16-128 chars). Ends up in state, prefer user_group_ids for RBAC"
  type        = string
  default     = null
  sensitive   = true
}

variable "user_group_ids" {
  description = "RBAC user group IDs (max 1)"
  type        = list(string)
  default     = []
}

variable "snapshot_retention_limit" {
  description = "Days to keep automatic snapshots, 0 turns them off"
  type        = number
  default     = 7
}

variable "snapshot_window" {
  description = "Daily snapshot window (UTC), e.g. 03:00-04:00"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window (UTC), e.g. sun:05:00-sun:06:00"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on delete"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply changes now instead of in the maintenance window"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Upgrade minor versions in the maintenance window"
  type        = bool
  default     = true
}

variable "notification_topic_arn" {
  description = "SNS topic for ElastiCache events"
  type        = string
  default     = null
}

variable "enable_slow_log" {
  description = "Send the slow log to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention for the slow log group"
  type        = number
  default     = 30
}

variable "log_kms_key_arn" {
  description = "KMS key for the slow log group (key policy must allow CloudWatch Logs)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
