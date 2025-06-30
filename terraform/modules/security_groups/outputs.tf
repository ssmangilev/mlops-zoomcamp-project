# modules/security_groups/outputs.tf

output "alb_security_group_id" {
  description = "The ID of the ALB security group."
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "The ID of the ECS security group."
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group."
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "The ID of the Redis security group."
  value       = aws_security_group.redis.id
}

output "kafka_security_group_id" {
  description = "The ID of the Kafka security group."
  value       = aws_security_group.kafka.id
}