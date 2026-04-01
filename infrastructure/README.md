# Infrastructure Deployment Guide

Complete guide to deploying EuroleagueTech Cloud Platform using Terraform.

---

## 🎯 Overview

This folder contains Terraform configuration for deploying a **serverless AWS platform** with:
- ✅ Frontend hosting (S3 + CloudFront CDN)
- ✅ API backend (API Gateway + Lambda)
- ✅ Database (DynamoDB single-table)
- ✅ Logging & monitoring (CloudWatch)
- ✅ 15 reusable Terraform modules

**Estimated deployment time**: 5-10 minutes  
**Estimated monthly cost**: ~$0.09 (dev environment)

---

## 📋 Prerequisites

### 1. AWS Account
```bash
# Verify AWS credentials are set up
aws sts get-caller-identity
# Should return your Account ID, User, and ARN
```

### 2. Tools Setup
```bash
# Terraform
terraform version  # Should be >= 1.0

# AWS CLI
aws --version  # Should be >= 2.0

# Verify AWS region (should default to eu-west-1)
aws configure get region
```

### 3. Environment Variables
```bash
export AWS_REGION=eu-west-1
export AWS_PROFILE=default  # Or your named profile
```

---

## 🚀 Deployment Steps

### Step 1: Configure Variables

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# CRITICAL: Replace TIMESTAMP with current date (e.g., 20260401)
nano terraform.tfvars  # or: code terraform.tfvars

# Example values to set:
# environment     = "dev"
# applicationid   = "spotech-001"

# S3 bucket names (MUST be globally unique!):
# s3_buckets = {
#   frontend = { bucket_name = "spotech-dev-frontend-20260401" }
#   data     = { bucket_name = "spotech-dev-data-20260401" }
#   logs     = { bucket_name = "spotech-dev-logs-20260401" }
# }
```

### Step 2: Initialize Terraform

```bash
# Download provider plugins and set up backend
terraform init -backend-config=backend-config-dev.tfvars

# Output should show:
# Terraform has been successfully initialized!
# - Backend config file references S3 bucket for state
# - AWS provider configured for eu-west-1
```

**⚠️ Backend State Note**:
- State is stored in S3 + DynamoDB for team collaboration
- See `backend-config-dev.tfvars` for current backend settings
- **DO NOT COMMIT**: Keep `backend-config-dev.tfvars` in .gitignore

### Step 3: Plan Deployment

```bash
# Preview what Terraform will create/modify
terraform plan -var-file=terraform.tfvars -out=tfplan

# Review output:
# - Should show ~21 resources to be created (first deployment)
# - Check for any errors or warnings
# - Never skip this step in production!
```

### Step 4: Apply Configuration

```bash
# Deploy infrastructure
terraform apply tfplan

# Confirmation:
# - Resources will be created in AWS
# - This takes 3-5 minutes (mostly waiting for CloudFront)
# - Monitor progress in output

# After successful apply, you'll see:
# Apply complete! Resources: 21 added, 0 changed, 0 destroyed.
```

**What gets created**:
- ✅ 3 S3 buckets (frontend, data, logs)
- ✅ CloudFront distribution (global CDN)
- ✅ 2 Lambda functions (vendors_api, teams_api)
- ✅ 1 DynamoDB table with 5 GSIs
- ✅ 1 API Gateway HTTP API (4 routes)
- ✅ CloudWatch log groups
- ✅ IAM roles and policies

### Step 5: Verify Deployment

```bash
# Get outputs
terraform output

# You should see:
# - api_endpoint = "https://xxxxx.execute-api.eu-west-1.amazonaws.com/dev"
# - cloudfront_domain_name = "d3fcc8h3s9oqtr.cloudfront.net"
# - dynamodb_table_name = "spotech-dev-main"

# Test API endpoint
API_URL=$(terraform output -raw api_endpoint)
curl $API_URL/vendors | jq .

# Expected response: JSON array of 36 vendors
```

### Step 6: Deploy Frontend

```bash
# Terraform automatically uploads HTML/CSS/JS to S3
# Uploaded to: s3://spotech-dev-frontend-TIMESTAMP/

# Verify frontend is accessible
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name)
curl https://$CLOUDFRONT_URL/index.html | head -20

# Access in browser
echo "Visit: https://$CLOUDFRONT_URL"
```

### Step 7: Populate DynamoDB (Initial Data)

```bash
# Backend contains migration script
cd ../data-migration

# Upload teams and vendors to DynamoDB
python upload_to_dynamodb.py

# Verify data
aws dynamodb scan --table-name spotech-dev-main \
  --select COUNT \
  --region eu-west-1

# Should show: Count=104 (20 teams + 36 vendors + 48 derived items)
```

---

## 📦 Project Structure

```
infrastructure/
├── provider.tf                    # AWS provider config
├── variables.tf                   # Input variable definitions (with docs)
├── outputs.tf                     # Output values (API URLs, etc.)
├── dev.tfvars                     # YOUR CONFIG (PRIVATE - .gitignored)
├── terraform.tfvars.example       # TEMPLATE (public reference)
│
├── s3_bucket.tf                   # S3 bucket resources
├── s3-bucket-cors-config.tf       # CORS configuration
├── s3-bucket-policy.tf            # Public access policies
├── cloudfront.tf                  # CDN distribution
│
├── dynamodb.tf                    # NoSQL table + GSIs
├── dynamodb-gsi.tf                # Global secondary indexes (separate file)
│
├── lambda.tf                      # Lambda function definitions
├── lambda-permissions.tf          # API Gateway → Lambda permissions
├── api-gateways.tf                # HTTP API v2 routes
│
├── iam.tf                         # IAM roles for Lambda execution
├── cloudwatch-log-group.tf        # Logging configuration
│
├── modules/                       # Reusable Terraform modules
│   ├── api-gatewayv2-api/
│   ├── api-gatewayv2-integration/
│   ├── api-gatewayv2-route/
│   ├── api-gatewayv2-stage/
│   ├── cloudfront/
│   ├── cloudwatch-log-group/
│   ├── dynamodb/
│   ├── iam-role/
│   ├── iam-role-policy/
│   ├── lambda-function/
│   ├── lambda-permission/
│   ├── s3-bucket/
│   ├── s3-bucket-cors-config/
│   ├── s3-bucket-policy/
│   ├── s3-bucket-sse-config/
│   └── s3-bucket-website-config/
│
├── data/                          # Data files (IAM policies, etc.)
│   └── iam_role_policies/
│       ├── lambda_assume_role_policy.json
│       ├── lambda_dynamodb_read_policy.json
│       └── lambda_cloudwatch_logs_policy.json
│
└── terraform.tfstate              # ⚠️ PRIVATE - Local state (commit .gitignore only)
```

---

## 🔧 Common Operations

### View Terraform State

```bash
# Show all managed resources
terraform state list

# Show specific resource details
terraform state show aws_dynamodb_table.main
```

### Update Configuration

```bash
# Edit variable file
nano terraform.tfvars

# Plan changes
terraform plan -var-file=terraform.tfvars

# Apply updates
terraform apply tfplan
```

### Scale or Modify Resources

```bash
# Example: Increase Lambda memory
# 1. Edit terraform.tfvars:
#    lambdas = {
#      vendors-api = { memory_size = 512 }  # Was 256
#    }

# 2. Plan and apply
terraform plan -var-file=terraform.tfvars
terraform apply

# CloudFormation automatically updates Lambda
```

### Destroy Infrastructure

```bash
# Preview destruction
terraform plan -destroy -var-file=terraform.tfvars

# Remove all resources
terraform destroy -var-file=terraform.tfvars

# Confirm: type 'yes'
# Takes 2-3 minutes to remove everything
```

**Cleanup Notes**:
- ✅ S3 buckets will be empty (force_destroy = true)
- ✅ DynamoDB table deleted with all data
- ✅ CloudFront, Lambda, API Gateway removed
- ⚠️ You'll need to delete S3 terraform state bucket manually (accounts for safety)

---

## 📊 Key Resources

### API Gateway HTTP API

Routes deployed:
| Method | Path | Handler | Purpose |
|--------|------|---------|---------|
| GET | /vendors | vendors_api | List all vendors |
| GET | /vendors/{vendorId} | vendors_api | Get vendor details |
| GET | /teams | teams_api | List all teams |
| GET | /teams/{teamId} | teams_api | Get team details |

**API URL Format**:
```
https://{api_id}.execute-api.eu-west-1.amazonaws.com/dev/vendors
```

### DynamoDB Single-Table Design

**Table**: `spotech-dev-main`  
**Data Volume**: 104 items (56 entities + 48 derived)  
**GSIs**: 5 (for different query patterns)  
**Billing**: Pay-per-request (no capacity provisioning)

**Access Patterns**:
- GET item by ID (primary key)
- Query by category/country (GSI1)
- Query vendor clients (GSI2 - reverse partnership)
- Query by status (GSI3)
- Query product usage (GSI4)
- Query team staff (GSI5)

### CloudFront CDN

**Origin**: S3 bucket (frontend)  
**Caching**: 
- Default: 24 hours
- Custom: SPA redirects 404/403 → /index.html
- Compression: gzip/brotli enabled

**Performance**:
- Edge locations: Global (216+ PoPs)
- Regional caches: Automatic failover
- Cost: ~$0.02/month (low traffic)

---

## 🔐 Security Best Practices

### Do's ✅
- ✅ Store `terraform.tfvars` in `.gitignore` (never commit)
- ✅ Use IAM roles for Lambda (never hardcode credentials)
- ✅ Enable encryption at rest (DynamoDB, S3)
- ✅ Review IAM policies for least-privilege
- ✅ Keep Terraform state in S3 with MFA delete

### Don'ts ❌
- ❌ Don't commit `terraform.tfvars` with credentials
- ❌ Don't use root AWS credentials
- ❌ Don't enable public S3 access (use CloudFront OAC)
- ❌ Don't hardcode API keys in code
- ❌ Don't skip `terraform plan` before apply

**Security Review**: See [SECURITY.md](../SECURITY.md) for findings

---

## 🐛 Troubleshooting

### Error: S3 bucket name already exists
**Cause**: S3 bucket names are globally unique  
**Solution**: Use different timestamp in `terraform.tfvars`
```bash
# Change from:
bucket_name = "spotech-dev-frontend-20260401"
# to:
bucket_name = "spotech-dev-frontend-20260402"
```

### Error: Lambda handler not found
**Cause**: Backend source code not in correct location  
**Solution**: Verify path in `terraform.tfvars`
```bash
# Should be relative to infrastructure/ folder
source_dir = "../backend/src"  # Correct
source_dir = "./backend/src"   # Wrong
```

### Error: DynamoDB table already exists
**Cause**: Previous deployment not fully cleaned up  
**Solution**: Check AWS console or run
```bash
# List existing tables
aws dynamodb list-tables --region eu-west-1

# Delete manually if needed
aws dynamodb delete-table --table-name spotech-dev-main \
  --region eu-west-1
```

### Slow CloudFront distribution creation
**Expected behavior**: CloudFront takes 5-10 minutes to deploy globally  
**Status check**:
```bash
terraform output cloudfront_domain_name  # May show "In Progress"
# Wait 5-10 minutes, then retry
```

---

## 📈 Cost Optimization

### Current Monthly Cost: ~$0.09 ✅

| Service | Cost | Optimization |
|---------|------|--------|
| DynamoDB | $0.02 | Pay-per-request is optimal for MVP |
| Lambda | $0.01 | 256MB memory sufficient |
| API Gateway | $0.03 | HTTP API cheaper than REST |
| CloudFront | $0.02 | Data transfer low |
| S3 | <$0.01 | Small static site |

### Cost Reduction Ideas (Phase 3)
- Use CloudFront caching aggressively (already enabled)
- Batch DynamoDB operations when possible
- Consider reserved capacity if traffic grows

---

## 📚 Documentation

- [Architecture Overview](../docs/ARCHITECTURE.md)
- [DynamoDB Schema Design](../docs/DYNAMODB-SCHEMA-DESIGN.md)
- [Backend Handler Docs](../backend/README.md)
- [AWS Well-Architected Review](../docs/ARCHITECTURE.md#aws-well-architected-framework)

---

## 🚨 Important Files

### ⚠️ DO NOT COMMIT
- `terraform.tfvars` (your configuration)
- `backend-config-dev.tfvars` (state backend)
- `*.tfstate` or `*.tfstate.*` (local state)
- `.terraform/` directory (cache)

### ✅ DO COMMIT
- `terraform.tfvars.example` (template)
- All `.tf` files (configuration)
- `modules/` (reusable components)
- `.gitignore` (security)

---

## 🤝 Contributing

- Document any new modules with README
- Include variable descriptions
- Add outputs for important resources
- Test locally before committing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

## 🔗 Related Resources

- [AWS Terraform Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/best-practices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

**Last Updated**: March 31, 2026  
**Maintained by**: EuroleagueTech Contributors  
**Status**: Production-Ready (Phase 2)
