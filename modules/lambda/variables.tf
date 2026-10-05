variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the function"
  type        = string
  default     = "Managed by Terraform"
}

variable "source_dir" {
  description = "Local folder to zip up. Use one of source_dir, filename, image_uri or s3_bucket"
  type        = string
  default     = null
}

variable "filename" {
  description = "Path to a pre-built deployment zip"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket holding the deployment zip (with s3_key)"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the deployment zip"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI for container-image functions"
  type        = string
  default     = null
}

variable "handler" {
  description = "Function entrypoint (ignored for container images)"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Runtime identifier (ignored for container images)"
  type        = string
  default     = "python3.12"
}

variable "architectures" {
  description = "Instruction set: [\"x86_64\"] or [\"arm64\"]"
  type        = list(string)
  default     = ["arm64"]
}

variable "memory_size" {
  description = "Memory in MB"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Timeout in seconds"
  type        = number
  default     = 10
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency. -1 means unreserved"
  type        = number
  default     = -1
}

variable "environment_variables" {
  description = "Environment variables for the function"
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "Subnets for VPC-attached functions. Empty means no VPC"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security groups for VPC-attached functions"
  type        = list(string)
  default     = []
}

variable "policy_arns" {
  description = "Extra managed policy ARNs for the execution role, keyed by a static name"
  type        = map(string)
  default     = {}
}

variable "inline_policy" {
  description = "Inline policy JSON to attach to the execution role"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
}

variable "tracing_mode" {
  description = "X-Ray tracing mode: PassThrough or Active. Null disables"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
