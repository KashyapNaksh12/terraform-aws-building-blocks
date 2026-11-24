output "event_bus_name" {
  description = "Name of the event bus"
  value       = aws_cloudwatch_event_bus.this.name
}

output "event_bus_arn" {
  description = "ARN of the event bus"
  value       = aws_cloudwatch_event_bus.this.arn
}

output "rule_arns" {
  description = "ARNs of the created rules, keyed by rule name"
  value       = { for name, rule in aws_cloudwatch_event_rule.this : name => rule.arn }
}
