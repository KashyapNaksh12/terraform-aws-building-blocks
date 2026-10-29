output "alarm_arns" {
  description = "Alarm ARNs keyed by alarm key, e.g. rds-main-cpu"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
}

output "alarm_names" {
  description = "Alarm names keyed by alarm key"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.alarm_name }
}
