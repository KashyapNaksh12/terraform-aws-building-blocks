output "web_acl_id" {
  description = "ID of the web ACL"
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_arn" {
  description = "ARN of the web ACL, pass it as web_acl_id to CloudFront"
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_name" {
  description = "Name of the web ACL"
  value       = aws_wafv2_web_acl.this.name
}

output "log_group_name" {
  description = "Log group for WAF logs (null if logging is off)"
  value       = try(aws_cloudwatch_log_group.this[0].name, null)
}
