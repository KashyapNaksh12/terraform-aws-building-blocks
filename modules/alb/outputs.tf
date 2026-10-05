output "lb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "lb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}

output "lb_zone_id" {
  description = "Hosted zone ID of the load balancer (for Route 53 alias records)"
  value       = aws_lb.this.zone_id
}

output "security_group_id" {
  description = "ID of the ALB security group. Allow this as a source on your targets' security group"
  value       = aws_security_group.this.id
}

output "target_group_arn" {
  description = "ARN of the default target group"
  value       = aws_lb_target_group.this.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (null if no certificate)"
  value       = try(aws_lb_listener.https[0].arn, null)
}
