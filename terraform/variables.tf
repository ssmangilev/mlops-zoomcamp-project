# Root variables.tf - Defines common variables for the entire project

variable "project_name" {
  description = "A unique name for the project to prefix resources."
  type        = string
  default     = "mlops-airflow" # Customize this
}

variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "eu-central-1" # Customize this
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets_cidrs" {
  description = "A list of CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets_cidrs" {
  description = "A list of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "database_subnets_cidrs" {
  description = "A list of CIDR blocks for database subnets (should be private)."
  type        = list(string)
  default     = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
}

variable "availability_zones" {
  description = "A list of availability zones to use."
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"] # Adjust to your region
}

# Airflow Database
variable "airflow_db_username" {
  description = "Username for the Airflow PostgreSQL database."
  type        = string
  default     = "airflow"
}

variable "airflow_db_password" {
  description = "Password for the Airflow PostgreSQL database."
  type        = string
  sensitive   = true
  default     = "airflow" # CHANGE THIS FOR PRODUCTION!
}

# MLflow Database
variable "mlflow_db_username" {
  description = "Username for the MLflow PostgreSQL database."
  type        = string
  default     = "mlflow"
}

variable "mlflow_db_password" {
  description = "Password for the MLflow PostgreSQL database."
  type        = string
  sensitive   = true
  default     = "mlflow_pass" # CHANGE THIS FOR PRODUCTION!
}

# Airflow specific
variable "airflow_image_tag" {
  description = "Docker image tag for Airflow."
  type        = string
  default     = "apache/airflow:3.0.1" # Matches docker-compose
}

variable "airflow_fernet_key" {
  description = "Fernet key for Airflow. Generate with 'python -c \"from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())\"'"
  type        = string
  sensitive   = true
  default     = "YOUR_FERNET_KEY_HERE" # CHANGE THIS FOR PRODUCTION!
}

variable "airflow_admin_username" {
  description = "Username for the Airflow admin user."
  type        = string
  default     = "airflow"
}

variable "airflow_admin_password" {
  description = "Password for the Airflow admin user."
  type        = string
  sensitive   = true
  default     = "airflow" # CHANGE THIS FOR PRODUCTION!
}

# MLflow specific
variable "mlflow_image_tag" {
  description = "Docker image tag for MLflow webserver. This will be an ECR image built from your Dockerfile."
  type        = string
  default     = "mlflow-webserver:latest" # You'll need to build and push this to ECR
}

variable "mlflow_access_key_id" {
  description = "Access key for MLflow to interact with S3 artifact store."
  type        = string
  sensitive   = true
  default     = "mlflow_access_key" # Change this for production and use IAM roles instead
}

variable "mlflow_secret_access_key" {
  description = "Secret access key for MLflow to interact with S3 artifact store."
  type        = string
  sensitive   = true
  default     = "mlflow_secret_key" # Change this for production and use IAM roles instead
}

# Kafka UI specific
variable "kafka_ui_image_tag" {
  description = "Docker image tag for Kafka UI."
  type        = string
  default     = "provectuslabs/kafka-ui:latest"
}

# ECS Cluster
variable "ecs_instance_type" {
  description = "EC2 instance type for ECS cluster instances."
  type        = string
  default     = "t3.medium" # Adjust based on your workload
}

variable "ecs_min_size" {
  description = "Minimum number of instances in the ECS Auto Scaling Group."
  type        = number
  default     = 1
}

variable "ecs_max_size" {
  description = "Maximum number of instances in the ECS Auto Scaling Group."
  type        = number
  default     = 3
}

variable "ecs_desired_capacity" {
  description = "Desired number of instances in the ECS Auto Scaling Group."
  type        = number
  default     = 1
}

# Monitoring
variable "grafana_image_tag" {
  description = "Docker image tag for Grafana."
  type        = string
  default     = "grafana/grafana:latest"
}

variable "prometheus_image_tag" {
  description = "Docker image tag for Prometheus."
  type        = string
  default     = "prom/prometheus:latest"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana."
  type        = string
  sensitive   = true
  default     = "admin123" # CHANGE THIS FOR PRODUCTION!
  sensitive = true
}