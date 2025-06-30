# modules/rds/variables.tf

variable "project_name" {
  description = "The project name."
  type        = string
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
}

variable "db_username" {
  description = "The master username for the database."
  type        = string
}

variable "db_password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "The EC2 instance type for the RDS instance."
  type        = string
  default     = "db.t3.micro"
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to associate with the RDS instance."
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "Name of the DB Subnet Group."
  type        = string
}

variable "allocated_storage" {
  description = "The allocated storage in GB."
  type        = number
  default     = 20
}

variable "skip_final_snapshot" {
  description = "Set to true to skip the final DB snapshot before deleting the DB instance."
  type        = bool
  default     = true
}