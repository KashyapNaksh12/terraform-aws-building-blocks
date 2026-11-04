output "hub_arn" {
  description = "ARN of the Security Hub"
  value       = aws_securityhub_account.this.arn
}

output "standards_subscription_arns" {
  description = "Standards subscription ARNs keyed by standard"
  value       = { for k, v in aws_securityhub_standards_subscription.this : k => v.id }
}
