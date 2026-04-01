# ============================================================================
# Development Environment - Outputs
# ============================================================================

# -----------------------------------------------------------------------------
# S3 Bucket Outputs
# -----------------------------------------------------------------------------
output "s3_bucket_ids" {
  description = "Map of S3 bucket logical names to bucket IDs"
  value = {
    for k, v in module.s3_bucket : k => v.s3-id
  }
}

output "s3_bucket_arns" {
  description = "Map of S3 bucket logical names to bucket ARNs"
  value = {
    for k, v in module.s3_bucket : k => v.s3-arn
  }
}

output "s3_bucket_regional_domain_names" {
  description = "Map of S3 bucket regional domain names"
  value = {
    for k, v in module.s3_bucket : k => v.bucket_regional_domain_name
  }
}

# -----------------------------------------------------------------------------
# S3 Website Endpoints
# -----------------------------------------------------------------------------
output "s3_website_endpoints" {
  description = "Map of S3 website endpoints (for buckets with website config)"
  value = {
    for k, v in module.s3_website_config : k => v.website_endpoint
  }
}

# -----------------------------------------------------------------------------
# CloudFront Outputs
# -----------------------------------------------------------------------------
output "cloudfront_distribution_ids" {
  description = "Map of CloudFront distribution IDs"
  value = {
    for k, v in module.cloudfront : k => v.distribution_id
  }
}

output "cloudfront_distribution_arns" {
  description = "Map of CloudFront distribution ARNs"
  value = {
    for k, v in module.cloudfront : k => v.distribution_arn
  }
}

output "cloudfront_domain_names" {
  description = "Map of CloudFront domain names (URLs to access your sites)"
  value = {
    for k, v in module.cloudfront : k => "https://${v.domain_name}"
  }
}

output "cloudfront_oac_ids" {
  description = "Map of CloudFront Origin Access Control IDs"
  value = {
    for k, v in module.cloudfront : k => v.oac_id
  }
}

# -----------------------------------------------------------------------------
# Summary Output (User-Friendly)
# -----------------------------------------------------------------------------
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment       = var.environment
    s3_buckets        = length(module.s3_bucket)
    cdn_distributions = length(module.cloudfront)
    dynamodb_tables   = length(module.dynamodb)
    iam_roles         = length(module.aws-iam-role)
    lambda_functions  = length(module.lambda)
    log_groups        = length(module.cloudwatch_log_group)
    website_urls      = {
      for k, v in module.cloudfront : k => "https://${v.domain_name}"
    }
  }
}

# -----------------------------------------------------------------------------
# DynamoDB Outputs
# -----------------------------------------------------------------------------
output "dynamodb_table_ids" {
  description = "Map of DynamoDB table names to table IDs"
  value = {
    for k, v in module.dynamodb : k => v.table_id
  }
}

output "dynamodb_table_arns" {
  description = "Map of DynamoDB table ARNs"
  value = {
    for k, v in module.dynamodb : k => v.table_arn
  }
}

output "dynamodb_table_stream_arns" {
  description = "Map of DynamoDB table stream ARNs (if streams enabled)"
  value = {
    for k, v in module.dynamodb : k => v.stream_arn
  }
}

# -----------------------------------------------------------------------------
# IAM Role Outputs
# -----------------------------------------------------------------------------
output "iam_role_arns" {
  description = "Map of IAM role ARNs (for Lambda execution)"
  value = {
    for k, v in module.aws-iam-role : k => v.iam_role_arn
  }
}

output "iam_role_ids" {
  description = "Map of IAM role IDs"
  value = {
    for k, v in module.aws-iam-role : k => v.iam_role_id
  }
}

output "iam_role_names" {
  description = "Map of IAM role names"
  value = {
    for k, v in module.aws-iam-role : k => v.iam_role_name
  }
}

# -----------------------------------------------------------------------------
# Lambda Function Outputs
# -----------------------------------------------------------------------------
output "lambda_function_arns" {
  description = "Map of Lambda function ARNs"
  value = {
    for k, v in module.lambda : k => v.lambda_function_arn
  }
}

output "lambda_function_invoke_arns" {
  description = "Map of Lambda function invoke ARNs (for API Gateway integration)"
  value = {
    for k, v in module.lambda : k => v.lambda_function_invoke_arn
  }
}

output "lambda_function_names" {
  description = "Map of Lambda function names"
  value = {
    for k, v in module.lambda : k => v.lambda_function_name
  }
}

output "lambda_function_qualified_arns" {
  description = "Map of Lambda function qualified ARNs (with version)"
  value = {
    for k, v in module.lambda : k => v.lambda_function_qualified_arn
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group Outputs
# -----------------------------------------------------------------------------
output "cloudwatch_log_group_arns" {
  description = "Map of CloudWatch log group ARNs"
  value = {
    for k, v in module.cloudwatch_log_group : k => v.log_group_arn
  }
}

output "cloudwatch_log_group_names" {
  description = "Map of CloudWatch log group names"
  value = {
    for k, v in module.cloudwatch_log_group : k => v.log_group_name
  }
}

# -----------------------------------------------------------------------------
# API Integration Reference (For Next Phase)
# -----------------------------------------------------------------------------
output "api_gateway_integration_config" {
  description = "Ready-to-use configuration for API Gateway Lambda integrations"
  value = {
    for k, v in module.lambda : k => {
      function_name = v.lambda_function_name
      invoke_arn    = v.lambda_function_invoke_arn
      function_arn  = v.lambda_function_arn
    }
  }
}

# -----------------------------------------------------------------------------
# API Gateway Outputs
# -----------------------------------------------------------------------------
output "api_gateway_ids" {
  description = "Map of API Gateway IDs"
  value = {
    for k, v in module.api_definitions : k => v.api_id
  }
}

output "api_gateway_endpoints" {
  description = "Map of API Gateway endpoint URLs (base URLs without stage)"
  value = {
    for k, v in module.api_definitions : k => v.api_endpoint
  }
}

output "api_gateway_urls" {
  description = "Map of full API Gateway URLs including stage"
  value = {
    for api_key, api in var.api_gtws : api_key => {
      for stage_key, stage in api.stages : stage_key => "${module.api_definitions[api_key].api_endpoint}/${stage.name}"
    }
  }
}

output "api_gateway_stage_invoke_urls" {
  description = "Ready-to-use API Gateway stage URLs for testing"
  value = {
    for k, v in module.api_stages : k => v.invoke_url
  }
}

