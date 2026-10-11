# cloudfront

CloudFront distribution with a single origin: either a private S3 bucket (through Origin Access Control) or a custom origin like an ALB. Viewers are always redirected to HTTPS, and the defaults change with the origin type: S3 gets cached and is read-only, a custom origin gets no caching and all methods passed through.

For S3 the module does **not** attach a bucket policy. A bucket can only have one policy and the `s3` module already manages it, so pass `s3_bucket_policy_json` into that module's `policy` input instead.

## Usage

Static site from S3:

```hcl
module "site_bucket" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/s3?ref=v1.0.0"

  bucket_prefix = "site-"
  policy        = module.site_cdn.s3_bucket_policy_json
}

module "site_cdn" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/cloudfront?ref=v1.0.0"

  name                = "site-prod"
  origin_type         = "s3"
  origin_domain_name  = module.site_bucket.bucket_regional_domain_name
  s3_bucket_arn       = module.site_bucket.bucket_arn
  default_root_object = "index.html"

  aliases             = ["www.example.com"]
  acm_certificate_arn = module.cdn_cert.certificate_arn # must be in us-east-1

  # single page app: let the client router handle unknown paths
  custom_error_responses = [
    { error_code = 403, response_code = 200, response_page_path = "/index.html" },
    { error_code = 404, response_code = 200, response_page_path = "/index.html" },
  ]
}
```

In front of an ALB:

```hcl
module "app_cdn" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/cloudfront?ref=v1.0.0"

  name               = "app-prod"
  origin_type        = "custom"
  origin_domain_name = "origin.example.com" # a name the ALB's certificate covers
}
```

The `custom_origin_config` default is `https-only`, so the origin needs a certificate for `origin_domain_name`. If you point it at the raw `*.elb.amazonaws.com` name, set `origin_protocol_policy = "http-only"` (see `examples/ecs-cloudfront`).

Point Route 53 at it with an alias using `domain_name` and `hosted_zone_id`.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name used for the distribution comment, tags and the origin access control | `string` | n/a | **yes** |
| `origin_type` | Origin type: s3 (private bucket through OAC) or custom (ALB or any HTTP server) | `string` | `"s3"` | no |
| `origin_domain_name` | Origin domain. For s3 use the bucket's regional domain name, for custom e.g. the ALB DNS name | `string` | n/a | **yes** |
| `origin_path` | Path prefix added to origin requests, e.g. /public. Empty for none | `string` | `""` | no |
| `s3_bucket_arn` | ARN of the origin bucket. Required for s3 origins, used to build s3_bucket_policy_json | `string` | `null` | no |
| `custom_origin_config` | Connection settings for custom origins | `object` | `{}` | no |
| `origin_custom_headers` | Headers CloudFront adds to origin requests, e.g. a shared secret the ALB can check | `map(string)` | `{}` | no |
| `aliases` | Custom domain names for the distribution. Needs acm_certificate_arn | `list(string)` | `[]` | no |
| `acm_certificate_arn` | ACM certificate ARN, must be in us-east-1. Null uses the default *.cloudfront.net certificate | `string` | `null` | no |
| `minimum_protocol_version` | Minimum TLS version for viewers (only with a custom certificate) | `string` | `"TLSv1.2_2021"` | no |
| `cache_policy_name` | Cache policy name. Null picks Managed-CachingOptimized for s3 and Managed-CachingDisabled for custom | `string` | `null` | no |
| `origin_request_policy_name` | Origin request policy name. Null picks none for s3 and Managed-AllViewerExceptHostHeader for custom | `string` | `null` | no |
| `response_headers_policy_name` | Response headers policy name. Null disables | `string` | `"Managed-SecurityHeadersPolicy"` | no |
| `allowed_methods` | HTTP methods CloudFront forwards. Null picks read-only for s3 and all methods for custom | `list(string)` | `null` | no |
| `default_root_object` | Object returned for requests to /, e.g. index.html | `string` | `null` | no |
| `custom_error_responses` | Custom error responses, e.g. map 403/404 to /index.html for single page apps | `list(object)` | `[]` | no |
| `price_class` | PriceClass_100, PriceClass_200 or PriceClass_All | `string` | `"PriceClass_100"` | no |
| `http_version` | Max HTTP version: http1.1, http2, http2and3 or http3 | `string` | `"http2and3"` | no |
| `ipv6_enabled` | Enable IPv6 | `bool` | `true` | no |
| `web_acl_id` | WAFv2 web ACL ARN (scope CLOUDFRONT). Null disables | `string` | `null` | no |
| `geo_restriction_type` | whitelist or blacklist, used when geo_restriction_locations is set | `string` | `"whitelist"` | no |
| `geo_restriction_locations` | ISO 3166-1 alpha-2 country codes for the geo restriction. Empty means no restriction | `list(string)` | `[]` | no |
| `logging_bucket` | Bucket domain name for standard access logs (bucket.s3.amazonaws.com). The bucket needs ACLs enabled. Null disables | `string` | `null` | no |
| `logging_prefix` | Prefix for access log objects | `string` | `null` | no |
| `enabled` | Whether the distribution accepts requests | `bool` | `true` | no |
| `wait_for_deployment` | Wait for the distribution to finish deploying (can take a few minutes) | `bool` | `true` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `distribution_id` | ID of the distribution (for cache invalidations) |
| `distribution_arn` | ARN of the distribution |
| `domain_name` | Distribution domain name (xxxx.cloudfront.net) |
| `hosted_zone_id` | Hosted zone ID of the distribution (for Route 53 alias records) |
| `origin_access_control_id` | ID of the origin access control (null for custom origins) |
| `s3_bucket_policy_json` | Bucket policy that lets this distribution read the bucket. Pass it to the s3 module's policy input (null for custom origins) |
<!-- END_TF_DOCS -->
