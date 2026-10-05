output "table_name" {
  description = "Name of the table"
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "ARN of the table"
  value       = aws_dynamodb_table.this.arn
}

output "stream_arn" {
  description = "ARN of the table stream (null if streams are disabled)"
  value       = var.stream_view_type != null ? aws_dynamodb_table.this.stream_arn : null
}
