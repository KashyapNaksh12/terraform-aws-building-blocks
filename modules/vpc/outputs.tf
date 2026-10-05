output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the internet gateway (null if no public subnets)"
  value       = try(aws_internet_gateway.this[0].id, null)
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_group_name" {
  description = "Name of the RDS DB subnet group (null if not created)"
  value       = try(aws_db_subnet_group.this[0].name, null)
}

output "public_route_table_ids" {
  description = "IDs of the public route tables"
  value       = aws_route_table.public[*].id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "IDs of the database route tables"
  value       = aws_route_table.database[*].id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = aws_nat_gateway.this[*].id
}

output "nat_public_ips" {
  description = "Elastic IPs attached to the NAT gateways"
  value       = aws_eip.nat[*].public_ip
}

output "azs" {
  description = "Availability zones used"
  value       = var.azs
}
