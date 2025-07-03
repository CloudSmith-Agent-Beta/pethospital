provider "aws" {
  region = var.region
}

# Use variables for consistent naming and configuration
locals {
  prefix       = var.project_prefix
  cluster_name = "${var.project_prefix}-eks-cluster"
  environment  = var.environment
  region       = var.region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  name                 = "${local.prefix}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = var.availability_zones
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    Environment                                   = local.environment
    Project                                       = local.prefix
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  region          = local.region

  node_groups = {
    main = {
      desired_capacity = var.eks_desired_capacity
      max_capacity     = var.eks_max_capacity
      min_capacity     = var.eks_min_capacity
      instance_types   = var.eks_instance_types
      disk_size        = var.eks_disk_size
    }
  }

  tags = {
    Environment = local.environment
    Project     = local.prefix
  }
}

# ElastiCache Redis Module (HIGH RISK - adds cost and complexity)
module "elasticache" {
  source = "./modules/elasticache"

  cluster_name           = "${local.prefix}-redis"
  node_type             = var.redis_node_type
  num_cache_nodes       = var.redis_num_nodes
  parameter_group_name  = "default.redis7"
  port                  = 6379
  subnet_group_name     = "${local.prefix}-redis-subnet-group"
  subnet_ids            = module.vpc.private_subnets
  security_group_ids    = [module.eks.cluster_security_group_id]
  
  tags = {
    Environment = local.environment
    Project     = local.prefix
  }
}

# DynamoDB Tables
module "dynamodb" {
  source = "./modules/dynamodb"

  tables = [
    {
      name         = "${local.prefix}-pets"
      billing_mode = "PAY_PER_REQUEST"
      hash_key     = "id"
      attributes = [
        {
          name = "id"
          type = "S"
        }
      ]
    },
    {
      name         = "${local.prefix}-hospitals"
      billing_mode = "PAY_PER_REQUEST"
      hash_key     = "id"
      attributes = [
        {
          name = "id"
          type = "S"
        }
      ]
    },
    {
      name         = "${local.prefix}-doctors"
      billing_mode = "PAY_PER_REQUEST"
      hash_key     = "id"
      attributes = [
        {
          name = "id"
          type = "S"
        }
      ]
    },
    {
      name         = "${local.prefix}-visits"
      billing_mode = "PAY_PER_REQUEST"
      hash_key     = "id"
      attributes = [
        {
          name = "id"
          type = "S"
        }
      ]
    },
    {
      name         = "${local.prefix}-billing"
      billing_mode = "PAY_PER_REQUEST"
      hash_key     = "id"
      attributes = [
        {
          name = "id"
          type = "S"
        }
      ]
    },
    {
      name         = "${local.prefix}-insurance"
      billing_mode = "PAY_PER_REQUEST"
      hash_key     = "id"
      attributes = [
        {
          name = "id"
          type = "S"
        }
      ]
    }
  ]

  tags = {
    Environment = local.environment
    Project     = local.prefix
  }
}

# ECR Repositories
module "ecr" {
  source = "./modules/ecr"

  repositories = [
    "${local.prefix}-pet-service",
    "${local.prefix}-hospital-service",
    "${local.prefix}-doctor-service",
    "${local.prefix}-billing-service",
    "${local.prefix}-insurance-service",
    "${local.prefix}-visit-service",
    "${local.prefix}-vet-service",
    "${local.prefix}-frontend"
  ]

  tags = {
    Environment = local.environment
    Project     = local.prefix
  }
}

# CloudWatch Monitoring
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name = local.cluster_name
  environment  = local.environment
  prefix       = local.prefix
  
  api_latency_threshold     = var.api_latency_threshold
  error_rate_threshold      = var.error_rate_threshold
  cpu_utilization_threshold = var.cpu_utilization_threshold
  memory_utilization_threshold = var.memory_utilization_threshold
  
  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = {
    Environment = local.environment
    Project     = local.prefix
  }
}

# ArgoCD Setup
module "argocd" {
  source = "./modules/argocd"

  cluster_name     = local.cluster_name
  environment      = local.environment
  cluster_endpoint = module.eks.cluster_endpoint
  prefix           = local.prefix
  
  tags = {
    Environment = local.environment
    Project     = local.prefix
  }

  # Add explicit dependency on EKS module
  depends_on = [module.eks]
}

# Output the cluster endpoint and other important information
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = local.cluster_name
}

output "ecr_repository_urls" {
  description = "URLs of the created ECR repositories"
  value       = module.ecr.repository_urls
}

output "dynamodb_table_names" {
  description = "Names of the created DynamoDB tables"
  value       = module.dynamodb.table_names
}

output "application_url" {
  description = "URL to access the application"
  value       = module.eks.application_url
}
