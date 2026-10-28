output "topic_arn" {
  description = "ARN of the topic"
  value       = aws_sns_topic.this.arn
}

output "topic_name" {
  description = "Name of the topic"
  value       = aws_sns_topic.this.name
}

output "subscription_arns" {
  description = "Subscription ARNs keyed like var.subscriptions"
  value       = { for k, v in aws_sns_topic_subscription.this : k => v.arn }
}
