variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_prefix" {
  description = "Prefix for all resources created by this project"
  type        = string
  default     = "pet-hospital"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# EKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.27"
}

# ElastiCache Configuration (HIGH RISK - adds cost)
variable "redis_node_type" {
  description = "Instance type for Redis ElastiCache nodes"
  type        = string
  default     = "cache.t3.micro"  # Smallest instance to minimize cost
}

variable "redis_num_nodes" {
  description = "Number of Redis cache nodes"
  type        = number
  default     = 1  # Single node to minimize cost (HIGH RISK - no redundancy)
}

variable "eks_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "eks_max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

variable "eks_min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "eks_instance_types" {
  description = "List of instance types for the EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_disk_size" {
  description = "Disk size for EKS worker nodes in GB"
  type        = number
  default     = 50
}

# Monitoring Configuration
variable "api_latency_threshold" {
  description = "Threshold for API latency alarm in milliseconds"
  type        = number
  default     = 1000
}

variable "error_rate_threshold" {
  description = "Threshold for error rate alarm in percentage"
  type        = number
  default     = 5
}

variable "cpu_utilization_threshold" {
  description = "Threshold for CPU utilization alarm in percentage"
  type        = number
  default     = 80
}

variable "memory_utilization_threshold" {
  description = "Threshold for memory utilization alarm in percentage"
  type        = number
  default     = 80
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm transitions to ALARM state"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of ARNs to notify when alarm transitions to OK state"
  type        = list(string)
  default     = []
}

# Git Repository Configuration
variable "git_repository_url" {
  description = "URL of the Git repository containing the application code"
  type        = string
  default     = "https://github.com/CloudSmith-Agent-Beta/pethospital.git"
}
