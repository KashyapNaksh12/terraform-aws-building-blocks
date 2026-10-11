variable "name" {
  description = "Name used for the distribution comment, tags and the origin access control"
  type        = string
}

variable "origin_type" {
  description = "Origin type: s3 (private bucket through OAC) or custom (ALB or any HTTP server)"
  type        = string
  default     = "s3"

  validation {
    condition     = contains(["s3", "custom"], var.origin_type)
    error_message = "origin_type must be s3 or custom"
  }
}

variable "origin_domain_name" {
  description = "Origin domain. For s3 use the bucket's regional domain name, for custom e.g. the ALB DNS name"
  type        = string
}

variable "origin_path" {
  description = "Path prefix added to origin requests, e.g. /public. Empty for none"
  type        = string
  default     = ""
}

variable "s3_bucket_arn" {
  description = "ARN of the origin bucket. Required for s3 origins, used to build s3_bucket_policy_json"
  type        = string
  default     = null
}

variable "custom_origin_config" {
  description = "Connection settings for custom origins"
  type = object({
    http_port                = optional(number, 80)
    https_port               = optional(number, 443)
    origin_protocol_policy   = optional(string, "https-only")
    origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])
    origin_read_timeout      = optional(number, 30)
    origin_keepalive_timeout = optional(number, 5)
  })
  default = {}
}

variable "origin_custom_headers" {
  description = "Headers CloudFront adds to origin requests, e.g. a shared secret the ALB can check"
  type        = map(string)
  default     = {}
}

variable "aliases" {
  description = "Custom domain names for the distribution. Needs acm_certificate_arn"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN, must be in us-east-1. Null uses the default *.cloudfront.net certificate"
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Minimum TLS version for viewers (only with a custom certificate)"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "cache_policy_name" {
  description = "Cache policy name. Null picks Managed-CachingOptimized for s3 and Managed-CachingDisabled for custom"
  type        = string
  default     = null
}

variable "origin_request_policy_name" {
  description = "Origin request policy name. Null picks none for s3 and Managed-AllViewerExceptHostHeader for custom"
  type        = string
  default     = null
}

variable "response_headers_policy_name" {
  description = "Response headers policy name. Null disables"
  type        = string
  default     = "Managed-SecurityHeadersPolicy"
}

variable "allowed_methods" {
  description = "HTTP methods CloudFront forwards. Null picks read-only for s3 and all methods for custom"
  type        = list(string)
  default     = null
}

variable "default_root_object" {
  description = "Object returned for requests to /, e.g. index.html"
  type        = string
  default     = null
}

variable "custom_error_responses" {
  description = "Custom error responses, e.g. map 403/404 to /index.html for single page apps"
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number, 10)
  }))
  default = []
}

variable "price_class" {
  description = "PriceClass_100, PriceClass_200 or PriceClass_All"
  type        = string
  default     = "PriceClass_100"
}

variable "http_version" {
  description = "Max HTTP version: http1.1, http2, http2and3 or http3"
  type        = string
  default     = "http2and3"
}

variable "ipv6_enabled" {
  description = "Enable IPv6"
  type        = bool
  default     = true
}

variable "web_acl_id" {
  description = "WAFv2 web ACL ARN (scope CLOUDFRONT). Null disables"
  type        = string
  default     = null
}

variable "geo_restriction_type" {
  description = "whitelist or blacklist, used when geo_restriction_locations is set"
  type        = string
  default     = "whitelist"
}

variable "geo_restriction_locations" {
  description = "ISO 3166-1 alpha-2 country codes for the geo restriction. Empty means no restriction"
  type        = list(string)
  default     = []
}

variable "logging_bucket" {
  description = "Bucket domain name for standard access logs (bucket.s3.amazonaws.com). The bucket needs ACLs enabled. Null disables"
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefix for access log objects"
  type        = string
  default     = null
}

variable "enabled" {
  description = "Whether the distribution accepts requests"
  type        = bool
  default     = true
}

variable "wait_for_deployment" {
  description = "Wait for the distribution to finish deploying (can take a few minutes)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
