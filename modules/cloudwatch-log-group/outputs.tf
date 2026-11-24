output "name" {
  description = "Name of the log group"
  value       = aws_cloudwatch_log_group.this.name
}

output "arn" {
  description = "ARN of the log group"
  value       = aws_cloudwatch_log_group.this.arn
}

output "arn_prefix" {
  description = "ARN of the log group without the trailing :*"
  value       = trimsuffix(aws_cloudwatch_log_group.this.arn, ":*")
}
