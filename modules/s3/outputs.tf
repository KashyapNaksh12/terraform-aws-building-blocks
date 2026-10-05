output "bucket_id" {
  description = "Name (ID) of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name (bucket.s3.amazonaws.com)"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Region-specific bucket domain name (use for CloudFront origins)"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
