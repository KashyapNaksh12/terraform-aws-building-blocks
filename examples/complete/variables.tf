variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "github_repo" {
  description = "owner/repo that can deploy through OIDC. Leave null to skip the CI role"
  type        = string
  default     = null
}
