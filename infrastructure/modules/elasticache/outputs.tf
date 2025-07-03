output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "Redis cluster port"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}

output "redis_cluster_id" {
  description = "Redis cluster ID"
  value       = aws_elasticache_cluster.redis.cluster_id
}
