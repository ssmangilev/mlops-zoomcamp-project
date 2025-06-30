# modules/elasticache_redis/main.tf

resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.project_name}-${var.cluster_name}"
  engine               = "redis"
  engine_version       = "7.0" # Close to 7.2-bookworm, but AWS manages versions differently.
  node_type            = "cache.t3.micro" # Or suitable for production
  num_cache_nodes      = 1 # For development, use more for production
  port                 = 6379
  parameter_group_name = "default.redis7"
  security_group_ids   = var.vpc_security_group_ids
  subnet_group_name    = var.subnet_group_name

  tags = {
    Name    = "${var.project_name}-${var.cluster_name}"
    Project = var.project_name
  }
}