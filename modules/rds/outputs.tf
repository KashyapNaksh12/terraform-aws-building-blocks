output "db_instance_id" {
  description = "Identifier of the DB instance"
  value       = aws_db_instance.this.identifier
}

output "db_instance_arn" {
  description = "ARN of the DB instance"
  value       = aws_db_instance.this.arn
}

output "endpoint" {
  description = "Connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "Hostname of the DB instance"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port the DB instance listens on"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Master username"
  value       = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master password"
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
}
