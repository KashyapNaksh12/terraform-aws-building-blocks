locals {
  is_s3     = var.origin_type == "s3"
  origin_id = "primary"

  # sensible defaults per origin: cache static files from s3, pass everything
  # through to an app behind an ALB
  cache_policy_name          = coalesce(var.cache_policy_name, local.is_s3 ? "Managed-CachingOptimized" : "Managed-CachingDisabled")
  origin_request_policy_name = var.origin_request_policy_name != null ? var.origin_request_policy_name : (local.is_s3 ? null : "Managed-AllViewerExceptHostHeader")
  allowed_methods            = coalesce(var.allowed_methods, local.is_s3 ? ["GET", "HEAD", "OPTIONS"] : ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])

  custom_certificate = var.acm_certificate_arn != null
}

data "aws_cloudfront_cache_policy" "this" {
  name = local.cache_policy_name
}

data "aws_cloudfront_origin_request_policy" "this" {
  count = local.origin_request_policy_name != null ? 1 : 0

  name = local.origin_request_policy_name
}

data "aws_cloudfront_response_headers_policy" "this" {
  count = var.response_headers_policy_name != null ? 1 : 0

  name = var.response_headers_policy_name
}

resource "aws_cloudfront_origin_access_control" "this" {
  count = local.is_s3 ? 1 : 0

  name                              = var.name
  description                       = "S3 access for ${var.name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  comment             = var.name
  enabled             = var.enabled
  is_ipv6_enabled     = var.ipv6_enabled
  http_version        = var.http_version
  price_class         = var.price_class
  aliases             = var.aliases
  default_root_object = var.default_root_object
  web_acl_id          = var.web_acl_id
  wait_for_deployment = var.wait_for_deployment

  origin {
    origin_id                = local.origin_id
    domain_name              = var.origin_domain_name
    origin_path              = var.origin_path
    origin_access_control_id = local.is_s3 ? aws_cloudfront_origin_access_control.this[0].id : null

    dynamic "custom_origin_config" {
      for_each = local.is_s3 ? [] : [var.custom_origin_config]

      content {
        http_port                = custom_origin_config.value.http_port
        https_port               = custom_origin_config.value.https_port
        origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
        origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
        origin_read_timeout      = custom_origin_config.value.origin_read_timeout
        origin_keepalive_timeout = custom_origin_config.value.origin_keepalive_timeout
      }
    }

    dynamic "custom_header" {
      for_each = var.origin_custom_headers

      content {
        name  = custom_header.key
        value = custom_header.value
      }
    }
  }

  default_cache_behavior {
    target_origin_id           = local.origin_id
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = local.allowed_methods
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.this.id
    origin_request_policy_id   = try(data.aws_cloudfront_origin_request_policy.this[0].id, null)
    response_headers_policy_id = try(data.aws_cloudfront_response_headers_policy.this[0].id, null)
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses

    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  dynamic "logging_config" {
    for_each = var.logging_bucket != null ? [1] : []

    content {
      bucket          = var.logging_bucket
      prefix          = var.logging_prefix
      include_cookies = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = length(var.geo_restriction_locations) > 0 ? var.geo_restriction_type : "none"
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = !local.custom_certificate
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = local.custom_certificate ? "sni-only" : null
    minimum_protocol_version       = local.custom_certificate ? var.minimum_protocol_version : "TLSv1"
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    precondition {
      condition     = length(var.aliases) == 0 || local.custom_certificate
      error_message = "aliases need an acm_certificate_arn (from us-east-1) that covers them."
    }

    precondition {
      condition     = !local.is_s3 || var.s3_bucket_arn != null
      error_message = "origin_type = \"s3\" needs s3_bucket_arn so the bucket policy can be generated."
    }
  }
}

# not attached here: the bucket can only have one policy and the s3 module
# already owns it. pass this into that module's `policy` input instead
data "aws_iam_policy_document" "s3_origin" {
  count = local.is_s3 ? 1 : 0

  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}
