# modules/ecs_services/variables.tf

variable "project_name" {
  description = "The project name."
  type        = string
}

variable "ecs_cluster_id" {
  description = "The ID of the ECS cluster."
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "The ID of the ECS security group."
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role."
  type        = string
}

# Airflow
variable "airflow_db_host" {
  description = "Hostname for the Airflow PostgreSQL database."
  type        = string
}

variable "airflow_db_username" {
  description = "Username for the Airflow PostgreSQL database."
  type        = string
}

variable "airflow_db_password" {
  description = "Password for the Airflow PostgreSQL database."
  type        = string
  sensitive   = true
}

variable "airflow_redis_endpoint" {
  description = "Endpoint for the Airflow Redis broker."
  type        = string
}

variable "airflow_image_tag" {
  description = "Docker image tag for Airflow."
  type        = string
}

variable "airflow_fernet_key" {
  description = "Fernet key for Airflow."
  type        = string
  sensitive   = true
}

variable "airflow_api_server_target_group_arn" {
  description = "ARN of the ALB target group for Airflow API Server."
  type        = string
}

variable "airflow_webserver_target_group_arn" {
  description = "ARN of the ALB target group for Airflow Webserver."
  type        = string
}

variable "airflow_admin_username" {
  description = "Username for the Airflow admin user."
  type        = string
}

variable "airflow_admin_password" {
  description = "Password for the Airflow admin user."
  type        = string
  sensitive   = true
}

# MLflow
variable "mlflow_db_host" {
  description = "Hostname for the MLflow PostgreSQL database."
  type        = string
}

variable "mlflow_db_username" {
  description = "Username for the MLflow PostgreSQL database."
  type        = string
}

variable "mlflow_db_password" {
  description = "Password for the MLflow PostgreSQL database."
  type        = string
  sensitive   = true
}

variable "mlflow_s3_bucket_name" {
  description = "Name of the S3 bucket for MLflow artifacts."
  type        = string
}

variable "mlflow_image_tag" {
  description = "Docker image tag for MLflow webserver."
  type        = string
}

variable "mlflow_webserver_target_group_arn" {
  description = "ARN of the ALB target group for MLflow Webserver."
  type        = string
}

variable "mlflow_access_key_id" {
  description = "Access key for MLflow to interact with S3 artifact store."
  type        = string
  sensitive   = true
}

variable "mlflow_secret_access_key" {
  description = "Secret access key for MLflow to interact with S3 artifact store."
  type        = string
  sensitive   = true
}

# Kafka UI
variable "kafka_ui_image_tag" {
  description = "Docker image tag for Kafka UI."
  type        = string
}

variable "kafka_brokers" {
  description = "Comma-separated list of Kafka broker endpoints."
  type        = string
}

variable "kafka_ui_target_group_arn" {
  description = "ARN of the ALB target group for Kafka UI."
  type        = string
}

# Monitoring
variable "grafana_image_tag" {
  description = "Docker image tag for Grafana."
  type        = string
}

variable "prometheus_image_tag" {
  description = "Docker image tag for Prometheus."
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

variable "efs_id" {
  description = "The ID of the EFS file system for shared volumes."
  type        = string
}