# modules/application_load_balancer/variables.tf

variable "project_name" {
  description = "The project name."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "public_subnets_ids" {
  description = "List of public subnet IDs where the ALB will be deployed."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "The ID of the ALB security group."
  type        = string
}

variable "airflow_webserver_port" {
  description = "Port for the Airflow Webserver/API."
  type        = number
  default     = 8080
}

variable "mlflow_webserver_port" {
  description = "Port for the MLflow Webserver."
  type        = number
  default     = 5000
}

variable "kafka_ui_port" {
  description = "Port for the Kafka UI."
  type        = number
  default     = 8081
}

variable "grafana_port" {
  description = "Port for Grafana."
  type        = number
  default     = 3000
}

variable "prometheus_port" {
  description = "Port for Prometheus."
  type        = number
  default     = 9090
}