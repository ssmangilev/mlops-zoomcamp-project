# modules/vpc/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnets_ids" {
  description = "List of public subnet IDs."
  value       = aws_subnet.public.*.id
}

output "private_subnets_ids" {
  description = "List of private subnet IDs."
  value       = aws_subnet.private.*.id
}

output "database_subnet_group_name" {
  description = "Name of the RDS DB Subnet Group."
  value       = aws_db_subnet_group.main.name
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache Subnet Group."
  value       = aws_elasticache_subnet_group.main.name
}