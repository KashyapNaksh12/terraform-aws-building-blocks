output "vault_name" {
  description = "Name of the backup vault"
  value       = aws_backup_vault.this.name
}

output "vault_arn" {
  description = "ARN of the backup vault"
  value       = aws_backup_vault.this.arn
}

output "plan_id" {
  description = "ID of the backup plan"
  value       = aws_backup_plan.this.id
}

output "plan_arn" {
  description = "ARN of the backup plan"
  value       = aws_backup_plan.this.arn
}

output "role_arn" {
  description = "IAM role AWS Backup uses"
  value       = var.role_arn != null ? var.role_arn : aws_iam_role.this[0].arn
}
