output "recorder_name" {
  description = "Name of the configuration recorder"
  value       = aws_config_configuration_recorder.this.name
}

output "role_arn" {
  description = "IAM role Config uses"
  value       = aws_config_configuration_recorder.this.role_arn
}

output "bucket_name" {
  description = "Bucket Config delivers to"
  value       = local.bucket_name
}

output "bucket_arn" {
  description = "ARN of the Config bucket"
  value       = local.bucket_arn
}

output "rule_arns" {
  description = "Config rule ARNs keyed by rule key"
  value       = { for k, v in aws_config_config_rule.this : k => v.arn }
}
