output "trail_arn" {
  description = "ARN of the trail"
  value       = aws_cloudtrail.this.arn
}

output "trail_name" {
  description = "Name of the trail"
  value       = aws_cloudtrail.this.name
}

output "bucket_name" {
  description = "Bucket the logs go to"
  value       = local.bucket_name
}

output "bucket_arn" {
  description = "ARN of the log bucket"
  value       = local.bucket_arn
}

output "log_group_name" {
  description = "CloudWatch log group of the trail, null if cloudwatch_logs_enabled = false"
  value       = try(aws_cloudwatch_log_group.this[0].name, null)
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.this[0].arn, null)
}

output "alarm_arns" {
  description = "Security alarm ARNs keyed by alarm key"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
}
