variable "identifier" {
  description = "Unique identifier for the DB instance"
  type        = string
}

variable "engine" {
  description = "Database engine: postgres, mysql, mariadb"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version (e.g. 16.4 for postgres, 8.0 for mysql)"
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "DB instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit for storage autoscaling in GiB. Set to 0 to disable autoscaling"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type: gp3, gp2, io1, io2"
  type        = string
  default     = "gp3"
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption. Null uses the AWS-managed RDS key"
  type        = string
  default     = null
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = null
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "port" {
  description = "Port to listen on. Null uses the engine default"
  type        = number
  default     = null
}

variable "db_subnet_group_name" {
  description = "Name of an existing DB subnet group. If null, one is created from subnet_ids"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for a new DB subnet group (used when db_subnet_group_name is null)"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Security group IDs to attach to the instance"
  type        = list(string)
  default     = []
}

variable "multi_az" {
  description = "Deploy a standby in another AZ"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Give the instance a public endpoint. Keep false for production"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to retain automated backups (0 disables)"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Daily backup window (UTC), e.g. 03:00-04:00"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window (UTC), e.g. sun:04:30-sun:05:30"
  type        = string
  default     = "sun:04:30-sun:05:30"
}

variable "deletion_protection" {
  description = "Prevent the instance from being deleted"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on deletion"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply modifications immediately instead of in the maintenance window"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Automatically apply minor engine upgrades"
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60). 0 disables"
  type        = number
  default     = 0
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Log types to export to CloudWatch (e.g. [\"postgresql\", \"upgrade\"])"
  type        = list(string)
  default     = []
}

variable "parameter_group_family" {
  description = "Parameter group family, e.g. postgres16. Leave null to use the default group"
  type        = string
  default     = null
}

variable "parameters" {
  description = "DB parameters for the custom parameter group"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))
  default = []
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
