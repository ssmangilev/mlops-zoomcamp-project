# modules/ecs_cluster/outputs.tf

output "ecs_cluster_id" {
  description = "The ID of the ECS cluster."
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster."
  value       = aws_ecs_cluster.main.name
}

output "airflow_ecr_repo_url" {
  description = "URL of the Airflow ECR repository."
  value       = aws_ecr_repository.airflow.repository_url
}

output "mlflow_webserver_ecr_repo_url" {
  description = "URL of the MLflow Webserver ECR repository."
  value       = aws_ecr_repository.mlflow_webserver.repository_url
}

output "kafka_ui_ecr_repo_url" {
  description = "URL of the Kafka UI ECR repository."
  value       = aws_ecr_repository.kafka_ui.repository_url
}