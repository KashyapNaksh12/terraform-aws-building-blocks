output "execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.execution.arn
}

output "execution_role_name" {
  description = "Name of the task execution role"
  value       = aws_iam_role.execution.name
}

output "task_role_arn" {
  description = "ARN of the task role (the app's permissions)"
  value       = aws_iam_role.task.arn
}

output "task_role_name" {
  description = "Name of the task role"
  value       = aws_iam_role.task.name
}
