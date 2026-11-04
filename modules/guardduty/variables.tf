variable "name" {
  description = "Prefix for the EventBridge rule"
  type        = string
  default     = "default"
}

variable "finding_publishing_frequency" {
  description = "How often updated findings are published: FIFTEEN_MINUTES, ONE_HOUR or SIX_HOURS"
  type        = string
  default     = "FIFTEEN_MINUTES"
}

variable "features" {
  description = "Protection plans to turn on or off. Each is billed separately"
  type        = map(bool)
  default = {
    S3_DATA_EVENTS         = true
    EKS_AUDIT_LOGS         = true
    EBS_MALWARE_PROTECTION = true
    RDS_LOGIN_EVENTS       = true
    LAMBDA_NETWORK_LOGS    = true
    RUNTIME_MONITORING     = false
  }
}

variable "runtime_monitoring_agents" {
  description = "Agent management for runtime monitoring: EKS_ADDON_MANAGEMENT, ECS_FARGATE_AGENT_MANAGEMENT, EC2_AGENT_MANAGEMENT"
  type        = map(bool)
  default = {
    EKS_ADDON_MANAGEMENT         = true
    ECS_FARGATE_AGENT_MANAGEMENT = true
    EC2_AGENT_MANAGEMENT         = true
  }
}

variable "export_bucket_arn" {
  description = "S3 bucket ARN to export findings to, for keeping them longer than 90 days. Bucket and key policies are up to you"
  type        = string
  default     = null
}

variable "export_kms_key_arn" {
  description = "KMS key for exported findings, required by GuardDuty when exporting"
  type        = string
  default     = null
}

variable "notifications" {
  description = "Send findings to an SNS topic (must allow events.amazonaws.com to publish). min_severity: 4 = medium, 7 = high, 9 = critical. Null turns it off"
  type = object({
    sns_topic_arn = string
    min_severity  = optional(number, 7)
  })
  default = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
