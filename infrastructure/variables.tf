# ============================================================================
# Infrastructure Variables - Project-Specific Defaults
# ============================================================================
# REQUIRED fields (AWS mandates): Must be in dev.tfvars
# OPTIONAL fields (project preferences): Can have defaults here
# ============================================================================

# -----------------------------------------------------------------------------
# Common/Global Variables
# -----------------------------------------------------------------------------
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "applicationid" {
  type        = string
  description = "Application ID for tagging"
}

variable "applicationname" {
  type        = string
  description = "Application name for tagging"
}

variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default     = "eu-west-1"  # Project default: Ireland
}

# -----------------------------------------------------------------------------
# S3 Buckets
# -----------------------------------------------------------------------------
variable "s3_buckets" {
  description = "Map of S3 buckets to create"
  type = map(object({
    # REQUIRED by AWS
    bucket_name = string
    
    # OPTIONAL - Project preferences with smart defaults
    purpose               = optional(string, "General Storage")
    force_destroy         = optional(bool, false)  # Safe default
    blockpublicacls       = optional(bool, true)   # Secure default
    blockpublicpolicy     = optional(bool, true)   # Secure default
    ignorepublicacls      = optional(bool, true)   # Secure default
    restrictpublicbuckets = optional(bool, true)   # Secure default
    enable_versioning     = optional(string, "Enabled")  # Best practice
    object_ownership      = optional(string, "BucketOwnerEnforced")
    specifictags          = optional(map(string), {})
    
    # Lifecycle rules - completely optional
    rules = optional(map(object({
      id     = string
      status = string
      expiration = optional(map(object({
        date = optional(string)  # No default - null if not provided
        days = optional(number)  # No default - null if not provided
      })), {})
      transition = optional(map(object({
        date          = optional(string)  # No default - null if not provided
        days          = optional(number)  # No default - null if not provided
        storage_class = string
      })), {})
      filters = optional(map(object({
        prefix                   = optional(string)  # No default - null if not provided
        object_size_greater_than = optional(number)  # No default - null if not provided
        object_size_less_than    = optional(number)  # No default - null if not provided
      })), {})
    })), {})
  }))

}

# -----------------------------------------------------------------------------
# S3 Website Configurations
# -----------------------------------------------------------------------------
variable "s3_website_configs" {
  description = "Map of S3 website configurations"
  type = map(object({
    # All optional - SPA-friendly defaults
    index_document_suffix = optional(string, "index.html")
    error_document_key    = optional(string, "index.html")
    routing_rules         = optional(list(object({
      condition = object({
        http_error_code_returned_equals = optional(string)
        key_prefix_equals               = optional(string)
      })
      redirect = object({
        host_name               = optional(string)
        http_redirect_code      = optional(string)
        protocol                = optional(string)
        replace_key_prefix_with = optional(string)
        replace_key_with        = optional(string)
      })
    })), [])
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# S3 Server-Side Encryption Configurations
# -----------------------------------------------------------------------------
variable "s3_sse_configs" {
  description = "Map of S3 encryption configurations"
  type = map(object({
    sse_algorithm = optional(string, "AES256")  # Free encryption
    kms_key_id    = optional(string)  # No default - null when not using KMS
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# S3 CORS Configurations
# -----------------------------------------------------------------------------
variable "s3_cors_configs" {
  description = "Map of S3 CORS configurations"
  type = map(object({
    expected_bucket_owner = optional(string)  # No default - null if not provided
    
    # REQUIRED by AWS if using CORS
    cors_rules = list(object({
      allowed_methods = list(string)  # REQUIRED
      allowed_origins = list(string)  # REQUIRED
      
      # Optional CORS fields
      allowed_headers = optional(list(string), ["*"])
      expose_headers  = optional(list(string), [])
      max_age_seconds = optional(number, 3600)
      id              = optional(string)  # No default - null if not provided
    }))
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# CloudFront Distributions
# -----------------------------------------------------------------------------
variable "cloudfront_distributions" {
  description = "Map of CloudFront distributions"
  type = map(object({
    # REQUIRED - must link to S3 bucket
    s3_bucket_key = string
    
    # OPTIONAL - Project defaults for CDN
    purpose                        = optional(string, "Static Website CDN")
    enabled                        = optional(bool, true)
    is_ipv6_enabled                = optional(bool, true)
    default_root_object            = optional(string, "index.html")
    comment                        = optional(string, "")
    price_class                    = optional(string, "PriceClass_100")  # Cost-optimized
    viewer_protocol_policy         = optional(string, "redirect-to-https")
    allowed_methods                = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods                 = optional(list(string), ["GET", "HEAD"])
    cache_policy_id                = optional(string, "658327ea-f89d-4fab-a63d-7e88639e58f6")
    compress                       = optional(bool, true)
    geo_restriction_type           = optional(string, "none")
    geo_restriction_locations      = optional(list(string), [])
    cloudfront_default_certificate = optional(bool, true)
    acm_certificate_arn            = optional(string, "")
    ssl_support_method             = optional(string, "sni-only")
    minimum_protocol_version       = optional(string, "TLSv1.2_2021")
    specifictags                   = optional(map(string), {})
    
    # SPA routing defaults
    custom_error_responses = optional(list(object({
      error_code            = number
      response_code         = number
      response_page_path    = string
      error_caching_min_ttl = number
    })), [
      {
        error_code            = 404
        response_code         = 200
        response_page_path    = "/index.html"
        error_caching_min_ttl = 300
      },
      {
        error_code            = 403
        response_code         = 200
        response_page_path    = "/index.html"
        error_caching_min_ttl = 300
      }
    ])
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# DynamoDB Tables
# -----------------------------------------------------------------------------
variable "dynamodb_tables" {
  description = "Map of DynamoDB tables to create"
  type = map(object({
    # REQUIRED by AWS
    table_name = string
    hash_key   = string  # Partition key (PK)
    range_key  = string  # Sort key (SK)
    
    # OPTIONAL - Project preferences
    purpose                       = optional(string, "NoSQL Database")
    billing_mode                  = optional(string, "PAY_PER_REQUEST")  # on-demand
    enable_point_in_time_recovery = optional(bool, false)
    enable_encryption             = optional(bool, true)
    stream_enabled                = optional(bool, false)
    specifictags                  = optional(map(string), {})
    
    # Global Secondary Indexes (GSIs)
    global_secondary_indexes = optional(list(object({
      name               = string
      hash_key           = string
      range_key          = optional(string)
      projection_type    = optional(string, "ALL")
      non_key_attributes = optional(list(string))
    })), [])
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# IAM Roles
# -----------------------------------------------------------------------------
variable "iam_roles" {
  description = "Map of IAM roles to create with their policies"
  type = map(object({
    # REQUIRED
    name               = string
    assume_role_policy = string  # Path to JSON policy file in data/iam_role_policies/
    
    # OPTIONAL
    specifictags = optional(map(string), {})
    
    # Inline policies (map of policy name to policy document path)
    policies = optional(map(object({
      name   = string
      policy = string  # Path to JSON policy file in data/iam_role_policies/
    })), {})
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Lambda Functions
# -----------------------------------------------------------------------------
variable "lambdas" {
  description = "Map of Lambda functions to create"
  type = map(object({
    # REQUIRED for Zip deployment
    function_name = string
    source_dir    = string  # Path to Lambda source code (e.g., "../backend/src")
    output_path   = string  # Path for zip file (e.g., "/tmp/vendors-api.zip")
    handler       = string  # Entry point (e.g., "handlers.vendors_api.lambda_handler")
    runtime       = string  # Python version (e.g., "python3.12")
    
    # OPTIONAL - Project preferences
    memory_size = optional(number, 256)  # MB
    timeout     = optional(number, 10)   # Seconds
    
    # Package type - defaults to Zip
    package_type = optional(string, "Zip")
    
    # Docker image support (optional, null for Zip deployment)
    image_uri = optional(string)
    
    # Environment variables
    environment_variables = optional(map(string), {})
    
    # Lambda layers
    layers = optional(list(string), [])
    
    # VPC configuration (optional, null = no VPC)
    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))
    
    # Tags
    specifictags = optional(map(string), {})
    
    # Environment override (uses global by default)
    environment = optional(string)
  }))
  default = {}
}

variable "cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups to create"
  type = map(object({
    name              = string
    retention_in_days = number
    specifictags      = optional(map(string), {})
  }))
  default = {}
}

variable "api_gtws" {
  description = "Map of API definitions"
  type = map(object({
    name                         = string
    protocol_type                = string
    api_key_selection_expression = optional(string)
    credentials_arn              = optional(string)
    description                  = optional(string)
    disable_execute_api_endpoint = optional(bool)
    route_key                    = optional(string)
    route_selection_expression   = optional(string)
    target                       = optional(string)
    api_version                  = optional(string)
    body                         = optional(string)
    fail_on_warnings             = optional(bool)
    integrations = map(object({
      integration_type          = string
      connection_id             = optional(string)
      connection_type           = optional(string)
      content_handling_strategy = optional(string)
      credentials_arn           = optional(string)
      description               = optional(string)
      integration_method        = optional(string)
      integration_subtype       = optional(string)
      integration_uri           = optional(string)
      lambda_key                = optional(string)  # Key to lookup Lambda invoke ARN
      passthrough_behavior      = optional(string)
      payload_format_version    = optional(string)
      request_parameters        = optional(map(string))
      request_templates         = optional(map(string))
      response_parameters = optional(list(object({
        mappings    = map(string)
        status_code = string
      })))
      template_selection_expression = optional(string)
      timeout_milliseconds          = optional(number)
      tls_config = optional(object({
        server_name_to_verify = optional(string)
      }))
    }))
    routes = map(object({
      route_key                  = string
      integration_key            = optional(string)  # Key to lookup integration
      api_key_required           = optional(bool)
      authorization_scopes       = optional(list(string))
      authorization_type         = optional(string)
      authorizer_id              = optional(string)
      model_selection_expression = optional(string)
      operation_name             = optional(string)
      request_models             = optional(map(string))
      request_parameters = optional(list(object({
        request_parameter_key = string
        required              = bool
      })))
      route_response_selection_expression = optional(string)
      target                              = optional(string)
    }))
    stages = map(object({
      name                  = string
      auto_deploy           = optional(bool)
      client_certificate_id = optional(string)
      deployment_id         = optional(string)
      description           = optional(string)
      stage_variables       = optional(map(string))
      access_log_settings = optional(object({
        destination_arn = string
        format          = string
      }))
      default_route_settings = optional(object({
        data_trace_enabled       = optional(bool)
        detailed_metrics_enabled = optional(bool)
        logging_level            = optional(string)
        throttling_burst_limit   = optional(number)
        throttling_rate_limit    = optional(number)
      }))
      route_settings = optional(object({
        route_key                = string
        data_trace_enabled       = optional(bool)
        detailed_metrics_enabled = optional(bool)
        logging_level            = optional(string)
        throttling_burst_limit   = optional(number)
        throttling_rate_limit    = optional(number)
      }))
      specifictags = optional(map(string))
      environment  = optional(string)
    }))
    specifictags = optional(map(string))
    environment  = optional(string)
  }))
}

variable "lambda_permissions" {
  description = "Map of Lambda permissions to create"
  type = map(object({
    statement_id  = string
    action        = string
    function_name = string
    principal     = string
    source_arn    = string
    function_url_auth_type = string
  }))
  default = {}
}