# ============================================================================
# Backend Configuration - Development Environment
# ============================================================================
# Remote state storage in S3 with DynamoDB locking
# Usage: terraform init -backend-config=backend-config-dev.tfvars
# ============================================================================

bucket         = "spotech-dev-s3-tfstate-577638377042-eu-west-1-an"
key            = "euroleaguetech-platform/dev/terraform.tfstate"
region         = "eu-west-1" # Ireland - same region as resources
dynamodb_table = "spotech-dev-ddb-tfstatelock"
