output "distribution_id" {
  description = "ID of the distribution (for cache invalidations)"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "ARN of the distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "Distribution domain name (xxxx.cloudfront.net)"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "Hosted zone ID of the distribution (for Route 53 alias records)"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "origin_access_control_id" {
  description = "ID of the origin access control (null for custom origins)"
  value       = try(aws_cloudfront_origin_access_control.this[0].id, null)
}

output "s3_bucket_policy_json" {
  description = "Bucket policy that lets this distribution read the bucket. Pass it to the s3 module's policy input (null for custom origins)"
  value       = try(data.aws_iam_policy_document.s3_origin[0].json, null)
}
