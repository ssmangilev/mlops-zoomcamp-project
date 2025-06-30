# modules/security_groups/variables.tf

variable "project_name" {
  description = "The project name."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for inter-service communication if needed."
  type        = list(string)
}