# modules/elasticache_redis/outputs.tf

output "redis_endpoint" {
  description = "The endpoint of the Redis cluster."
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}