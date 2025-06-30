# modules/s3_artifact_store/variables.tf

variable "project_name" {
  description = "The project name."
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket for MLflow artifacts."
  type        = string
}