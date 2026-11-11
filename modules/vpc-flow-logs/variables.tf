variable "name" {
  description = "Name used for the log group and role prefix, usually the VPC name"
  type        = string
}

variable "vpc_id" {
  description = "VPC to capture flow logs for"
  type        = string
}

variable "traffic_type" {
  description = "Traffic type to capture: ACCEPT, REJECT, or ALL"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.traffic_type)
    error_message = "traffic_type must be ACCEPT, REJECT, or ALL"
  }
}

variable "retention_days" {
  description = "Retention in days for the flow logs log group"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "KMS key ARN for the flow logs log group. The key policy must allow CloudWatch Logs"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
