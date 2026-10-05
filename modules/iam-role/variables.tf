variable "name" {
  description = "Name of the IAM role"
  type        = string
}

variable "description" {
  description = "Description of the IAM role"
  type        = string
  default     = "Managed by Terraform"
}

variable "path" {
  description = "IAM path for the role"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds (3600-43200)"
  type        = number
  default     = 3600
}

variable "permissions_boundary_arn" {
  description = "ARN of a permissions boundary policy"
  type        = string
  default     = null
}

variable "assume_role_policy" {
  description = "Custom trust policy JSON. Overrides trusted_* and github_oidc_*"
  type        = string
  default     = null
}

variable "trusted_services" {
  description = "Service principals that can assume the role, e.g. lambda.amazonaws.com"
  type        = list(string)
  default     = []
}

variable "trusted_role_arns" {
  description = "IAM principal ARNs (accounts, roles, users) allowed to assume the role"
  type        = list(string)
  default     = []
}

variable "github_oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN"
  type        = string
  default     = null
}

variable "github_oidc_subjects" {
  description = "GitHub OIDC sub claims to allow, e.g. repo:my-org/my-repo:ref:refs/heads/main"
  type        = list(string)
  default     = []
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub OIDC provider. Only one can exist per account"
  type        = bool
  default     = false
}

variable "managed_policy_arns" {
  description = "Managed policies to attach, as name => arn"
  type        = map(string)
  default     = {}
}

variable "inline_policies" {
  description = "Inline policy JSON documents, keyed by policy name"
  type        = map(string)
  default     = {}
}

variable "create_instance_profile" {
  description = "Also create an EC2 instance profile for this role"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
