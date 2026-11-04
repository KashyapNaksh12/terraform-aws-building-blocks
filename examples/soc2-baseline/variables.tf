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
  default     = "prod"
}

variable "alert_email" {
  description = "Email address for security alerts. Confirm the subscription from the email AWS sends. Null skips it"
  type        = string
  default     = null
}

variable "security_contact" {
  description = "Security alternate contact for the account. Null skips it"
  type = object({
    name  = string
    title = string
    email = string
    phone = string
  })
  default = null
}
