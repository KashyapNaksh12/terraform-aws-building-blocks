output "url" {
  description = "Public URL of the app"
  value       = "https://${local.custom_domain ? var.domain_name : module.cdn.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidations)"
  value       = module.cdn.distribution_id
}

output "alb_dns_name" {
  description = "ALB DNS name. Only reachable from CloudFront"
  value       = module.alb.lb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.app.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.app.service_name
}

output "log_group_name" {
  description = "CloudWatch log group for the app"
  value       = module.app.log_group_name
}
