# Root main.tf - Orchestrates the AWS infrastructure deployment

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "ssmangilev-zoomcamp-mlops-course-state-bucket" # REMEMBER TO CHANGE THIS
    key            = "mlops-airflow/terraform.tfstate"
    region         = "eu-central-1" # REMEMBER TO CHANGE THIS
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------
# Module Calls
# ---------------------------------------------------

module "iam_roles" {
  source = "./modules/iam_roles"
}

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  private_subnets_cidrs = var.private_subnets_cidrs
  public_subnets_cidrs  = var.public_subnets_cidrs
  database_subnets_cidrs = var.database_subnets_cidrs
  availability_zones    = var.availability_zones
}

module "security_groups" {
  source = "./modules/security_groups"

  vpc_id = module.vpc.vpc_id
  project_name = var.project_name
  private_subnet_ids = module.vpc.private_subnets_ids
}

module "rds_airflow" {
  source = "./modules/rds"

  project_name            = var.project_name
  db_name                 = "airflow"
  db_username             = var.airflow_db_username
  db_password             = var.airflow_db_password
  db_instance_class       = "db.t3.micro"
  vpc_security_group_ids  = [module.security_groups.rds_security_group_id]
  db_subnet_group_name    = module.vpc.database_subnet_group_name
  allocated_storage       = 20
  skip_final_snapshot     = true # Set to false for production
}

module "rds_mlflow" {
  source = "./modules/rds"

  project_name            = var.project_name
  db_name                 = "mlflow"
  db_username             = var.mlflow_db_username
  db_password             = var.mlflow_db_password
  db_instance_class       = "db.t3.micro"
  vpc_security_group_ids  = [module.security_groups.rds_security_group_id]
  db_subnet_group_name    = module.vpc.database_subnet_group_name
  allocated_storage       = 20
  skip_final_snapshot     = true # Set to false for production
}

module "elasticache_redis" {
  source = "./modules/elasticache_redis"

  project_name          = var.project_name
  cluster_name          = "airflow-redis-broker"
  vpc_security_group_ids = [module.security_groups.redis_security_group_id]
  subnet_group_name     = module.vpc.private_subnets_ids[0] # Use one of the private subnets for ElastiCache
  # Note: ElastiCache subnet group requires at least two subnets in different AZs.
  # Adjust subnet group creation in `vpc` module accordingly.
}

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  bucket_name  = "${var.project_name}-mlflow-artifacts"
}

module "ecs_cluster" {
  source = "./modules/ecs_cluster"

  project_name            = var.project_name
  ecs_instance_type       = var.ecs_instance_type
  min_size                = var.ecs_min_size
  max_size                = var.ecs_max_size
  desired_capacity        = var.ecs_desired_capacity
  vpc_id                  = module.vpc.vpc_id
  public_subnets_ids      = module.vpc.public_subnets_ids
  private_subnets_ids     = module.vpc.private_subnets_ids
  instance_profile_name   = module.iam_roles.ecs_instance_profile_name
  ecs_security_group_id   = module.security_groups.ecs_security_group_id
  ecr_repository_names    = ["airflow", "mlflow-webserver", "kafka-ui"] # Pre-create ECR repos
}

module "application_load_balancer" {
  source = "./modules/application_load_balancer"

  project_name              = var.project_name
  vpc_id                    = module.vpc.vpc_id
  public_subnets_ids        = module.vpc.public_subnets_ids
  alb_security_group_id     = module.security_groups.alb_security_group_id
  airflow_webserver_port    = 8080
  mlflow_webserver_port     = 5000
  kafka_ui_port             = 8081
  grafana_port              = 3000
  prometheus_port           = 9090
}

module "ecs_services" {
  source = "./modules/ecs_services"

  project_name                  = var.project_name
  ecs_cluster_id                = module.ecs_cluster.ecs_cluster_id
  ecs_cluster_name              = module.ecs_cluster.ecs_cluster_name
  private_subnet_ids            = module.vpc.private_subnets_ids
  ecs_security_group_id         = module.security_groups.ecs_security_group_id
  ecs_task_execution_role_arn   = module.iam_roles.ecs_task_execution_role_arn
  ecs_task_role_arn             = module.iam_roles.ecs_task_role_arn

  # Airflow
  airflow_db_host               = module.rds_airflow.db_endpoint
  airflow_db_username           = var.airflow_db_username
  airflow_db_password           = var.airflow_db_password
  airflow_redis_endpoint        = module.elasticache_redis.redis_endpoint
  airflow_image_tag             = var.airflow_image_tag
  airflow_fernet_key            = var.airflow_fernet_key
  airflow_api_server_target_group_arn = module.application_load_balancer.airflow_api_server_tg_arn
  airflow_webserver_target_group_arn = module.application_load_balancer.airflow_webserver_tg_arn
  airflow_admin_username        = var.airflow_admin_username
  airflow_admin_password        = var.airflow_admin_password

  # MLflow
  mlflow_db_host                = module.rds_mlflow.db_endpoint
  mlflow_db_username            = var.mlflow_db_username
  mlflow_db_password            = var.mlflow_db_password
  mlflow_s3_bucket_name         = module.s3_artifact_store.bucket_id
  mlflow_image_tag              = var.mlflow_image_tag
  mlflow_webserver_target_group_arn = module.application_load_balancer.mlflow_webserver_tg_arn
  mlflow_access_key_id          = var.mlflow_access_key_id
  mlflow_secret_access_key      = var.mlflow_secret_access_key

  # Kafka UI
  kafka_ui_image_tag            = var.kafka_ui_image_tag
  kafka_brokers                 = module.msk_kafka.broker_string
  kafka_ui_target_group_arn     = module.application_load_balancer.kafka_ui_tg_arn

  # Monitoring
  grafana_image_tag             = var.grafana_image_tag
  prometheus_image_tag          = var.prometheus_image_tag
  grafana_admin_password        = var.grafana_admin_password
  grafana_target_group_arn      = module.application_load_balancer.grafana_tg_arn
  prometheus_target_group_arn   = module.application_load_balancer.prometheus_tg_arn
}

module "msk_kafka" {
  source = "./modules/msk_kafka"

  project_name            = var.project_name
  vpc_id                  = module.vpc.vpc_id
  private_subnets_ids     = module.vpc.private_subnets_ids
  security_group_id       = module.security_groups.kafka_security_group_id
  broker_instance_type    = "kafka.t3.small"
  number_of_broker_nodes  = 2
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name            = var.project_name
  ecs_cluster_name        = module.ecs_cluster.ecs_cluster_name
  grafana_admin_password  = var.grafana_admin_password
  grafana_target_group_arn = module.application_load_balancer.grafana_tg_arn
  prometheus_target_group_arn = module.application_load_balancer.prometheus_tg_arn
}