# modules/rds/outputs.tf

output "db_endpoint" {
  description = "The endpoint of the RDS instance."
  value       = aws_db_instance.main.address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance."
  value       = aws_db_instance.main.arn
}