# modules/monitoring/main.tf

# This module can be extended to include:
# - CloudWatch Alarms for ECS Service health, CPU/Memory utilization
# - CloudWatch Dashboards for overall application health
# - SNS topics for notifications
# - More sophisticated Prometheus configuration (e.g., service discovery with ECS)
# For now, it mainly sets up the necessary log groups which are created in ecs_services.
# The Prometheus and Grafana applications themselves are deployed via ECS services.

# Example: CloudWatch Alarm for Airflow Webserver CPU utilization
resource "aws_cloudwatch_metric_alarm" "airflow_webserver_cpu_utilization" {
  alarm_name          = "${var.project_name}-airflow-webserver-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when Airflow Webserver CPU utilization exceeds 80%"
  actions_enabled     = true

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "mlops-airflow-airflow-apiserver" # Use the actual service name
  }

  # Replace with your SNS topic ARN for notifications
  # alarm_actions = ["arn:aws:sns:REGION:ACCOUNT_ID:YOUR_SNS_TOPIC"]
}