# modules/msk_kafka/outputs.tf

output "broker_string" {
  description = "The connection string for Kafka brokers."
  value       = aws_msk_cluster.main.bootstrap_brokers_sasl_iam # Or _tls or _plaintext depending on client_authentication
}

output "cluster_arn" {
  description = "The ARN of the MSK cluster."
  value       = aws_msk_cluster.main.arn
}