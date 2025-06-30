# modules/vpc/variables.tf

variable "project_name" {
  description = "The project name."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "private_subnets_cidrs" {
  description = "A list of CIDR blocks for private subnets."
  type        = list(string)
}

variable "public_subnets_cidrs" {
  description = "A list of CIDR blocks for public subnets."
  type        = list(string)
}

variable "database_subnets_cidrs" {
  description = "A list of CIDR blocks for database subnets (should be private)."
  type        = list(string)
}

variable "availability_zones" {
  description = "A list of availability zones to use."
  type        = list(string)
}