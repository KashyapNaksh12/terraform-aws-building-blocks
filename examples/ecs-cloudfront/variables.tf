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

variable "image" {
  description = "Container image to run"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "domain_name" {
  description = "Custom domain for CloudFront, e.g. app.example.com. Leave null to use the cloudfront.net domain"
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Route 53 zone for domain_name (cert validation + alias record). Required when domain_name is set"
  type        = string
  default     = null
}
