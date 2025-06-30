# modules/elasticache_redis/variables.tf

variable "project_name" {
  description = "The project name."
  type        = string
}

variable "cluster_name" {
  description = "The name for the ElastiCache Redis cluster."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to associate with the ElastiCache cluster."
  type        = list(string)
}

variable "subnet_group_name" {
  description = "Name of the ElastiCache subnet group."
  type        = string
}