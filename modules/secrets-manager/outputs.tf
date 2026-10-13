output "secret_id" {
  description = "ID of the secret (same as the ARN)"
  value       = aws_secretsmanager_secret.this.id
}

output "secret_arn" {
  description = "ARN of the secret"
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  description = "Name of the secret"
  value       = aws_secretsmanager_secret.this.name
}

output "version_id" {
  description = "ID of the version created by this module (null if create_value is false)"
  value       = try(aws_secretsmanager_secret_version.this[0].version_id, aws_secretsmanager_secret_version.ignore_changes[0].version_id, null)
}
