# modules/s3_artifact_store/main.tf

resource "aws_s3_bucket" "mlflow_artifacts" {
  bucket = var.bucket_name
  acl    = "private" # Restrict public access

  tags = {
    Name    = "${var.project_name}-mlflow-artifacts"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "mlflow_artifacts_versioning" {
  bucket = aws_s3_bucket.mlflow_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mlflow_artifacts_sse" {
  bucket = aws_s3_bucket.mlflow_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "evidently_metrics" {
  bucket = var.bucket_name
  acl    = "private" # Restrict public access

  tags = {
    Name    = "${var.project_name}-evidently_metrics"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "evidently_metrics_versioning" {
  bucket = aws_s3_bucket.evidently_metrics.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "evidently_metrics_sse" {
  bucket = aws_s3_bucket.evidently_metrics.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}