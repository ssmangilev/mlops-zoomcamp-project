# modules/rds/main.tf

resource "aws_db_instance" "main" {
  allocated_storage    = var.allocated_storage
  engine               = "postgres"
  engine_version       = "16" # Matches docker-compose
  instance_class       = var.db_instance_class
  identifier           = "${var.project_name}-${var.db_name}-db"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres16"
  skip_final_snapshot  = var.skip_final_snapshot
  db_subnet_group_name = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible = false # Private database

  tags = {
    Name    = "${var.project_name}-${var.db_name}-db"
    Project = var.project_name
  }
}