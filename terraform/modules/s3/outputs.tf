# modules/s3_artifact_store/outputs.tf

output "bucket_id" {
  description = "The ID of the S3 bucket."
  value       = aws_s3_bucket.mlflow_artifacts.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.mlflow_artifacts.arn
}