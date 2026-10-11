output "cluster_arn" {
  description = "ARN of the cluster the service runs in"
  value       = local.cluster_arn
}

output "cluster_name" {
  description = "Name of the cluster the service runs in"
  value       = local.cluster_name
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ARN of the task definition (with revision)"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Task definition family"
  value       = aws_ecs_task_definition.this.family
}

output "security_group_id" {
  description = "ID of the task security group. Allow this as a source on databases etc."
  value       = aws_security_group.this.id
}

output "task_role_arn" {
  description = "ARN of the task role (the app's permissions)"
  value       = aws_iam_role.task.arn
}

output "task_role_name" {
  description = "Name of the task role"
  value       = aws_iam_role.task.name
}

output "execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.execution.arn
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.this.name
}
