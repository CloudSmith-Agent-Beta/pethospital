# ElastiCache Redis Cluster
# HIGH RISK: This adds significant cost and network complexity

resource "aws_elasticache_subnet_group" "redis" {
  name       = var.subnet_group_name
  subnet_ids = var.subnet_ids

  tags = var.tags
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = var.cluster_name
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = var.parameter_group_name
  port                 = var.port
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = var.security_group_ids

  # HIGH RISK: Automatic failover and backup settings
  apply_immediately          = true
  auto_minor_version_upgrade = true
  maintenance_window         = "sun:03:00-sun:04:00"
  
  # CRITICAL: No snapshot retention for cost savings (HIGH RISK for data loss)
  snapshot_retention_limit = 0
  snapshot_window         = "02:00-03:00"

  tags = merge(var.tags, {
    Name = var.cluster_name
  })
}

# CloudWatch Alarms for monitoring (adds cost but improves reliability)
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${var.cluster_name}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors redis cpu utilization"
  alarm_actions       = []

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.cluster_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${var.cluster_name}-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors redis memory utilization"
  alarm_actions       = []

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.cluster_id
  }

  tags = var.tags
}
