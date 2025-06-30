# modules/msk_kafka/variables.tf

variable "project_name" {
  description = "The project name."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnets_ids" {
  description = "List of private subnet IDs for MSK brokers."
  type        = list(string)
}

variable "security_group_id" {
  description = "The ID of the Kafka security group."
  type        = string
}

variable "broker_instance_type" {
  description = "EC2 instance type for Kafka brokers."
  type        = string
  default     = "kafka.t3.small"
}

variable "number_of_broker_nodes" {
  description = "Number of Kafka broker nodes (multiples of 2 for high availability)."
  type        = number
  default     = 2
}