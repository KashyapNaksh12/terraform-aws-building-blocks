output "repository_name" {
  description = "Name of the repository"
  value       = aws_ecr_repository.this.name
}

output "repository_arn" {
  description = "ARN of the repository"
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "URL of the repository (use as the image name for docker push)"
  value       = aws_ecr_repository.this.repository_url
}

output "registry_id" {
  description = "Registry (account) ID the repository lives in"
  value       = aws_ecr_repository.this.registry_id
}
