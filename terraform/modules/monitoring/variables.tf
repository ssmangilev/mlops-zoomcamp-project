# modules/monitoring/variables.tf

variable "project_name" {
  description = "The project name."
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster."
  type        = string
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana."
  type        = string
  sensitive   = true
}

variable "grafana_target_group_arn" {
  description = "ARN of the ALB target group for Grafana."
  type        = string
}

variable "prometheus_target_group_arn" {
  description = "ARN of the ALB target group for Prometheus."
  type        = string
}