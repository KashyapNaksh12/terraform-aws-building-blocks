output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "role_unique_id" {
  description = "Stable unique ID of the IAM role"
  value       = aws_iam_role.this.unique_id
}

output "instance_profile_name" {
  description = "Name of the instance profile (null if not created)"
  value       = try(aws_iam_instance_profile.this[0].name, null)
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider used by the role (null if unused)"
  value       = local.github_oidc_provider_arn
}
