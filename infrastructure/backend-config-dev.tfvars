# ============================================================================
# Backend Configuration - Development Environment
# ============================================================================
# Remote state storage in S3 with DynamoDB locking
# Usage: terraform init -backend-config=backend-config-dev.tfvars
#
# Prerequisites (create manually via AWS Console or CLI):
# 1. S3 bucket: spotech-dev-s3-tfstate (eu-west-1)
# 2. DynamoDB table: spotech-dev-ddb-tfstatelock (eu-west-1)
# ============================================================================

bucket         = "spotech-dev-s3-tfstate-577638377042-eu-west-1-an"
key            = "tfstate/terraform-spotech-dev.tfstate"
region         = "eu-west-1" # Ireland - same region as resources
dynamodb_table = "spotech-dev-ddb-tfstatelock"
