resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.cluster_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "app/${var.cluster_name}-alb/*"]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "API Latency"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "app/${var.cluster_name}-alb/*"],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "app/${var.cluster_name}-alb/*"]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "HTTP Errors"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["ContainerInsights", "node_failed_count", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Maximum"
          region = data.aws_region.current.name
          title  = "Failed Nodes"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["ContainerInsights", "pod_cpu_utilization", "ClusterName", var.cluster_name],
            ["ContainerInsights", "pod_memory_utilization", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Pod Resource Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Node CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["ContainerInsights", "node_memory_utilization", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Node Memory Utilization"
        }
      }
    ]
  })
}

# API Latency Alarm
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.cluster_name}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = var.api_latency_threshold / 1000 # Convert from ms to seconds
  alarm_description   = "This metric monitors API latency"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    LoadBalancer = "app/${var.cluster_name}-alb/*"
  }
  
  tags = var.tags
}

# Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.cluster_name}-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_description   = "This metric monitors API error rate"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    LoadBalancer = "app/${var.cluster_name}-alb/*"
  }
  
  tags = var.tags
}

# Get current AWS region
data "aws_region" "current" {}

# Container Insights - Pod CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "container_insights_pod_cpu" {
  alarm_name          = "${var.cluster_name}-pod-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "pod_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold
  alarm_description   = "This metric monitors pod CPU utilization using Container Insights"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    ClusterName = var.cluster_name
  }
  
  tags = var.tags
}

# Container Insights - Pod Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "container_insights_pod_memory" {
  alarm_name          = "${var.cluster_name}-pod-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "pod_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_utilization_threshold
  alarm_description   = "This metric monitors pod memory utilization using Container Insights"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    ClusterName = var.cluster_name
  }
  
  tags = var.tags
}

# Container Insights - Node CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "container_insights_node_cpu" {
  alarm_name          = "${var.cluster_name}-node-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold
  alarm_description   = "This metric monitors node CPU utilization using Container Insights"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    ClusterName = var.cluster_name
  }
  
  tags = var.tags
}

# Container Insights - Node Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "container_insights_node_memory" {
  alarm_name          = "${var.cluster_name}-node-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_utilization_threshold
  alarm_description   = "This metric monitors node memory utilization using Container Insights"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    ClusterName = var.cluster_name
  }
  
  tags = var.tags
}

# Container Insights - Node Disk Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "container_insights_node_disk" {
  alarm_name          = "${var.cluster_name}-node-disk-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_filesystem_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80 # 80% disk utilization threshold
  alarm_description   = "This metric monitors node disk utilization using Container Insights"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    ClusterName = var.cluster_name
  }
  
  tags = var.tags
}

# Container Insights - Node Network Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "container_insights_node_network" {
  alarm_name          = "${var.cluster_name}-node-network-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_network_total_bytes"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 1000000000 # 1GB network traffic threshold
  alarm_description   = "This metric monitors node network utilization using Container Insights"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    ClusterName = var.cluster_name
  }
  
  tags = var.tags
}
