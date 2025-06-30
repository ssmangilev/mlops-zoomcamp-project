# modules/ecs_services/outputs.tf

output "airflow_apiserver_service_name" {
  description = "Name of the Airflow API Server ECS service."
  value       = aws_ecs_service.airflow_apiserver.name
}

output "mlflow_webserver_service_name" {
  description = "Name of the MLflow Webserver ECS service."
  value       = aws_ecs_service.mlflow_webserver.name
}