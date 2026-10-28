output "file_system_id" {
  description = "ID of the file system"
  value       = aws_efs_file_system.this.id
}

output "file_system_arn" {
  description = "ARN of the file system"
  value       = aws_efs_file_system.this.arn
}

output "dns_name" {
  description = "DNS name for mounting"
  value       = aws_efs_file_system.this.dns_name
}

output "mount_target_ids" {
  description = "Mount target IDs keyed like var.mount_target_subnet_ids"
  value       = { for k, v in aws_efs_mount_target.this : k => v.id }
}

output "access_point_ids" {
  description = "Access point IDs keyed like var.access_points"
  value       = { for k, v in aws_efs_access_point.this : k => v.id }
}

output "access_point_arns" {
  description = "Access point ARNs keyed like var.access_points"
  value       = { for k, v in aws_efs_access_point.this : k => v.arn }
}
