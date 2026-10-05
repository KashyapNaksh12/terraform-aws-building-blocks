output "instance_id" {
  description = "ID of the instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the instance"
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP (the Elastic IP when create_eip = true)"
  value       = var.create_eip ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.this.availability_zone
}

output "iam_role_name" {
  description = "Name of the created IAM role (null if not created)"
  value       = try(aws_iam_role.this[0].name, null)
}

output "iam_role_arn" {
  description = "ARN of the created IAM role (null if not created)"
  value       = try(aws_iam_role.this[0].arn, null)
}

output "ami_id" {
  description = "AMI the instance was launched from"
  value       = aws_instance.this.ami
}
