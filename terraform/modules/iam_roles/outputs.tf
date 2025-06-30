# modules/iam_roles/outputs.tf

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role."
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_instance_profile_name" {
  description = "Name of the ECS instance profile."
  value       = aws_iam_instance_profile.ecs_instance_profile.name
}