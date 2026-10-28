output "queue_url" {
  description = "URL of the queue"
  value       = aws_sqs_queue.this.id
}

output "queue_arn" {
  description = "ARN of the queue"
  value       = aws_sqs_queue.this.arn
}

output "queue_name" {
  description = "Name of the queue"
  value       = aws_sqs_queue.this.name
}

output "dlq_url" {
  description = "URL of the DLQ (null if create_dlq is false)"
  value       = try(aws_sqs_queue.dlq[0].id, null)
}

output "dlq_arn" {
  description = "ARN of the DLQ (null if create_dlq is false)"
  value       = try(aws_sqs_queue.dlq[0].arn, null)
}
