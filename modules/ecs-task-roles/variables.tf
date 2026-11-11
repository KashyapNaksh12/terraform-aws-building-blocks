variable "name" {
  description = "Name of the service, used as the prefix for the role names"
  type        = string
}

variable "secrets" {
  description = "Secrets the container reads, env var name => Secrets Manager or SSM parameter ARN. The execution role gets read access to them"
  type        = map(string)
  default     = {}
}

variable "secrets_kms_key_arns" {
  description = "Customer-managed KMS keys the secrets are encrypted with, keyed by a static name. The execution role gets kms:Decrypt on them"
  type        = map(string)
  default     = {}
}

variable "execution_role_policy_arns" {
  description = "Extra managed policies for the execution role"
  type        = map(string)
  default     = {}
}

variable "task_role_policy_arns" {
  description = "Managed policies for the task role (the app's permissions), keyed by a static name"
  type        = map(string)
  default     = {}
}

variable "task_role_inline_policy" {
  description = "Inline policy JSON for the task role"
  type        = string
  default     = null
}

variable "enable_execute_command" {
  description = "Give the task role the SSM messages permissions `aws ecs execute-command` needs"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
