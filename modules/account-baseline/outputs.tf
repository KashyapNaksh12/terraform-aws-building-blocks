output "access_analyzer_arn" {
  description = "ARN of the external access analyzer"
  value       = try(aws_accessanalyzer_analyzer.this[0].arn, null)
}

output "unused_access_analyzer_arn" {
  description = "ARN of the unused access analyzer"
  value       = try(aws_accessanalyzer_analyzer.unused[0].arn, null)
}

output "support_role_arn" {
  description = "ARN of the aws-support role"
  value       = try(aws_iam_role.support[0].arn, null)
}
