# Root outputs.tf - Defines important outputs for the entire project

output "airflow_webserver_url" {
  description = "URL for the Airflow Webserver."
  value       = "http://${module.application_load_balancer.alb_dns_name}:8080"
}

output "mlflow_webserver_url" {
  description = "URL for the MLflow Webserver."
  value       = "http://${module.application_load_balancer.alb_dns_name}:5000"
}

output "kafka_ui_url" {
  description = "URL for the Kafka UI."
  value       = "http://${module.application_load_balancer.alb_dns_name}:8081"
}

output "grafana_url" {
  description = "URL for Grafana."
  value       = "http://${module.application_load_balancer.alb_dns_name}:3000"
}

output "prometheus_url" {
  description = "URL for Prometheus."
  value       = "http://${module.application_load_balancer.alb_dns_name}:9090"
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster."
  value       = module.ecs_cluster.ecs_cluster_name
}