output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_url" {
  description = "Public URL of the load balancer"
  value       = "http://${module.alb.lb_dns_name}"
}

output "web_instance_ids" {
  description = "Web server instance IDs (connect with: aws ssm start-session --target <id>)"
  value       = { for k, m in module.web : k => m.instance_id }
}

output "assets_bucket" {
  description = "Assets bucket name"
  value       = module.assets.bucket_id
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = module.db.endpoint
}

output "db_password_secret_arn" {
  description = "Secrets Manager ARN holding the DB master password"
  value       = module.db.master_user_secret_arn
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}

output "github_actions_role_arn" {
  description = "Role ARN to use in aws-actions/configure-aws-credentials"
  value       = try(module.github_actions_role[0].role_arn, null)
}
