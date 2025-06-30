# modules/ecs_cluster/variables.tf

variable "project_name" {
  description = "The project name."
  type        = string
}

variable "ecs_instance_type" {
  description = "EC2 instance type for ECS cluster instances."
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in the ECS Auto Scaling Group."
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in the ECS Auto Scaling Group."
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances in the ECS Auto Scaling Group."
  type        = number
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "public_subnets_ids" {
  description = "List of public subnet IDs for ECS tasks that need public access (e.g., ALB)."
  type        = list(string)
}

variable "private_subnets_ids" {
  description = "List of private subnet IDs for ECS instances and tasks."
  type        = list(string)
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile for ECS EC2 instances."
  type        = string
}

variable "ecs_security_group_id" {
  description = "The ID of the ECS security group."
  type        = string
}

variable "ecr_repository_names" {
  description = "A list of ECR repository names to create."
  type        = list(string)
  default     = []
}

variable "efs_id" {
  description = "The ID of the EFS file system for shared volumes."
  type        = string
  # IMPORTANT: You'll need to create a separate EFS module and pass its ID here.
  # This is crucial for shared Airflow DAGs, logs, and plugins.
  # If not using EFS, adjust user_data in launch_configuration accordingly.
}