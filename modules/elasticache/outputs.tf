output "replication_group_id" {
  description = "ID of the replication group"
  value       = aws_elasticache_replication_group.this.id
}

output "replication_group_arn" {
  description = "ARN of the replication group"
  value       = aws_elasticache_replication_group.this.arn
}

output "primary_endpoint_address" {
  description = "Primary endpoint (cluster mode disabled)"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint (cluster mode disabled)"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint (cluster mode enabled)"
  value       = aws_elasticache_replication_group.this.configuration_endpoint_address
}

output "port" {
  description = "Port"
  value       = aws_elasticache_replication_group.this.port
}
