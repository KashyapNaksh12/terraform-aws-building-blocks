output "function_name" {
  description = "Name of the function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the function"
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Invoke ARN (for API Gateway integrations)"
  value       = aws_lambda_function.this.invoke_arn
}

output "qualified_arn" {
  description = "ARN including the latest published version"
  value       = aws_lambda_function.this.qualified_arn
}

output "role_name" {
  description = "Name of the execution role"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the execution role"
  value       = aws_iam_role.this.arn
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.this.name
}
