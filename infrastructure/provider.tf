# ============================================================================
# Terraform Configuration
# ============================================================================
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4"
    }
  }

  # Remote State Backend Configuration
  # State and locks stored in S3 + DynamoDB for team collaboration
  # Configuration values: backend-config-dev.tfvars
  # Initialize: terraform init -backend-config=backend-config-dev.tfvars
  backend "s3" {}
}

# ============================================================================
# AWS Provider Configuration
# ============================================================================
provider "aws" {
  region  = var.aws_region
  profile = "default"

  # Default tags applied to all resources
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = "SportsTech-Cloud-Platform"
      Environment = var.environment
    }
  }
}