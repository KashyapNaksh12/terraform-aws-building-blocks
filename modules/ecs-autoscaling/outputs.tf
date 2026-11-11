output "target_resource_id" {
  description = "Resource ID of the scalable target (service/<cluster>/<service>)"
  value       = aws_appautoscaling_target.this.resource_id
}

output "cpu_policy_arn" {
  description = "ARN of the CPU target tracking policy"
  value       = aws_appautoscaling_policy.cpu.arn
}

output "memory_policy_arn" {
  description = "ARN of the memory target tracking policy, null when memory_target is not set"
  value       = try(aws_appautoscaling_policy.memory[0].arn, null)
}
