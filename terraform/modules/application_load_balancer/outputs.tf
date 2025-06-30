# modules/application_load_balancer/outputs.tf

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer."
  value       = aws_lb.main.arn
}

output "airflow_api_server_tg_arn" {
  description = "ARN of the Airflow API Server Target Group."
  value       = aws_lb_target_group.airflow_api_server.arn
}

output "airflow_webserver_tg_arn" {
  description = "ARN of the Airflow Webserver Target Group."
  value       = aws_lb_target_group.airflow_webserver.arn
}

output "mlflow_webserver_tg_arn" {
  description = "ARN of the MLflow Webserver Target Group."
  value       = aws_lb_target_group.mlflow_webserver.arn
}

output "kafka_ui_tg_arn" {
  description = "ARN of the Kafka UI Target Group."
  value       = aws_lb_target_group.kafka_ui.arn
}

output "grafana_tg_arn" {
  description = "ARN of the Grafana Target Group."
  value       = aws_lb_target_group.grafana.arn
}

output "prometheus_tg_arn" {
  description = "ARN of the Prometheus Target Group."
  value       = aws_lb_target_group.prometheus.arn
}