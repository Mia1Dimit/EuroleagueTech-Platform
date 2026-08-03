# ============================================================================
# Development Environment - Variable Values
# ============================================================================
# Only specify values that differ from defaults in variables.tf
# Project defaults handle common settings (versioning, encryption, etc.)
# ============================================================================

# -----------------------------------------------------------------------------
# Global/Common Configuration
# -----------------------------------------------------------------------------
environment     = "dev"
applicationid   = "spotech-001"
applicationname = "EuroleagueTech-Cloud-Platform"
# aws_region uses default: "eu-west-1"
# -----------------------------------------------------------------------------
# DynamoDB Tables Configuration
# -----------------------------------------------------------------------------
# Single-table design: All entities (teams, vendors, products, partnerships, staff) in one table
# Pattern: PK = entity type + ID, SK = metadata or related entity
# GSIs enable different query patterns (category, country, vendor clients, etc.)
# -----------------------------------------------------------------------------

dynamodb_tables = {

  # Main table for all SportsTech data
  main = {
    table_name   = "spotech-dev-main"
    hash_key     = "PK" # Partition key: TEAM#<id>, VENDOR#<id>, etc.
    range_key    = "SK" # Sort key: METADATA, PARTNERSHIP#..., etc.
    purpose      = "Single-table design for team/vendors/products/partnerships"
    billing_mode = "PAY_PER_REQUEST" # On-demand (no capacity planning)

    specifictags = {
      DataModel = "Single-Table"
      Entities  = "Teams/Vendor/Products/Partnerships/Staff"
    }

    # Global Secondary Indexes for query access patterns
    global_secondary_indexes = [

      # GSI1: Query by category or country
      # Use case: "Show all GPS vendors" or "Show all Spanish teams"
      {
        name            = "GSI1"
        hash_key        = "GSI1PK" # CATEGORY#<category> or COUNTRY#<country>
        range_key       = "GSI1SK" # VENDOR#<vendorId> or TEAM#<teamId>
        projection_type = "ALL"
      },

      # GSI2: Query vendor clients (reverse partnership query)
      # Use case: "Show all teams using Catapult"
      {
        name            = "GSI2"
        hash_key        = "GSI2PK" # VENDOR#<vendorId>
        range_key       = "GSI2SK" # PARTNERSHIP#<teamId>
        projection_type = "ALL"
      },

      # GSI3: Query by partnership status and timeline
      # Use case: "Show recently confirmed partnerships"
      {
        name            = "GSI3"
        hash_key        = "GSI3PK" # STATUS#CONFIRMED, STATUS#LIKELY, etc.
        range_key       = "GSI3SK" # <confirmationDate>
        projection_type = "ALL"
      },

      # GSI4: Query product usage
      # Use case: "Which teams use KINEXON PERFORM?"
      {
        name            = "GSI4"
        hash_key        = "GSI4PK" # PRODUCT#<productId>
        range_key       = "GSI4SK" # TEAM#<teamId>
        projection_type = "ALL"
      },

      # GSI5: Query team staff roster (optional - can also query main table directly)
      # Use case: "Show all staff for Real Madrid"
      {
        name            = "GSI5"
        hash_key        = "GSI5PK" # TEAM#<teamId>
        range_key       = "GSI5SK" # STAFF#<staffId>
        projection_type = "ALL"
      }

    ]
  }

}
# -----------------------------------------------------------------------------
# S3 Buckets Configuration
# -----------------------------------------------------------------------------
# Map keys (frontend, data, logs) are LOGICAL references used by other resources
# bucket_name is the ACTUAL AWS bucket name (must be globally unique)
# -----------------------------------------------------------------------------
s3_buckets = {

  # Frontend static website bucket
  frontend = {
    bucket_name           = "spotech-dev-frontend-20260320"
    purpose               = "Static Website Hosting - React Frontend"
    force_destroy         = true  # Dev only - allows clean destruction
    blockpublicpolicy     = false # CloudFront needs access (override default)
    ignorepublicacls      = false # CloudFront OAC requires this
    restrictpublicbuckets = false
    specifictags = {
      Component = "Frontend"
      Framework = "React"
    }
    enable_versioning = "Enabled" # Keep versions for rollback
    object_ownership  = "BucketOwnerEnforced"
  }

  # Data/uploads bucket
  data = {
    bucket_name = "spotech-dev-data-20260320"
    purpose     = "Application Data Storage - User Uploads and Research Data"
    specifictags = {
      Component = "Backend"
      DataType  = "UserUploads"
    }
    # Lifecycle rule: transition old data to cheaper storage
    rules = {
      archive_old_data = {
        id     = "archive-old-uploads"
        status = "Enabled"
        transition = {
          glacier = {
            days          = 90
            storage_class = "GLACIER"
          }
        }
        filters = {
          uploads = {
            prefix = "uploads/"
          }
        }
      }
    }
  }

  # Logs bucket
  logs = {
    bucket_name       = "spotech-dev-logs-20260320"
    purpose           = "Application and Access Logs"
    force_destroy     = true       # Dev only - logs are ephemeral
    enable_versioning = "Disabled" # Logs don't need versioning
    object_ownership  = "BucketOwnerEnforced"
    specifictags = {
      Component = "Observability"
      LogType   = "ApplicationLogs"
    }
    rules = {
      delete_old_logs = {
        id     = "delete-old-logs"
        status = "Enabled"
        expiration = {
          standard = {
            days = 30
          }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Log Groups
# -----------------------------------------------------------------------------
# Lambda functions automatically create log groups if they don't exist,
# but pre-creating them lets us control retention period and tags
# Pattern: /aws/lambda/<function-name>
# -----------------------------------------------------------------------------
cloudwatch_log_groups = {

  # Log group for vendors API Lambda
  vendors-api = {
    name              = "/aws/lambda/spotech-dev-vendors-api"
    retention_in_days = 14
  }

  # Log group for teams API Lambda
  teams-api = {
    name              = "/aws/lambda/spotech-dev-teams-api"
    retention_in_days = 14
  }

}

# -----------------------------------------------------------------------------
# IAM Roles
# -----------------------------------------------------------------------------
# Each Lambda needs an execution role with:
# 1. Trust policy (assume_role_policy) - allows Lambda service to use the role
# 2. Inline policies - permissions to access AWS services (DynamoDB, CloudWatch)
# -----------------------------------------------------------------------------
iam_roles = {

  # Execution role for vendors API Lambda
  vendors-api-role = {
    name               = "spotech-dev-vendors-api-role"
    assume_role_policy = "lambda_assume_role_policy.json"
    policies = {
      dynamodb-read = {
        name   = "spotech-dev-vendors-api-dynamodb-read"
        policy = "lambda_dynamodb_read_policy.json"
      }
      cloudwatch-logs = {
        name   = "spotech-dev-vendors-api-cloudwatch-logs"
        policy = "lambda_cloudwatch_logs_policy.json"
      }
      xray = {
        name   = "spotech-dev-vendors-api-xray"
        policy = "lambda_xray_policy.json"
      }
    }
    specifictags = {}
  }

  # Execution role for teams API Lambda
  teams-api-role = {
    name               = "spotech-dev-teams-api-role"
    assume_role_policy = "lambda_assume_role_policy.json"
    policies = {
      dynamodb-read = {
        name   = "spotech-dev-teams-api-dynamodb-read"
        policy = "lambda_dynamodb_read_policy.json"
      }
      cloudwatch-logs = {
        name   = "spotech-dev-teams-api-cloudwatch-logs"
        policy = "lambda_cloudwatch_logs_policy.json"
      }
      xray = {
        name   = "spotech-dev-teams-api-xray"
        policy = "lambda_xray_policy.json"
      }
    }
    specifictags = {}
  }

}

# -----------------------------------------------------------------------------
# Lambda Functions
# -----------------------------------------------------------------------------
# API Lambda functions - serve HTTP requests via API Gateway
# Each handler routes requests and queries DynamoDB
# -----------------------------------------------------------------------------
lambdas = {

  # Vendors API - GET /vendors, GET /vendors/{id}
  vendors-api = {
    function_name = "spotech-dev-vendors-api"
    source_dir    = "../backend/src"
    output_path   = ".terraform/builds/vendors-api.zip"
    handler       = "handlers.vendors_api.lambda_handler"
    runtime       = "python3.12"
    memory_size   = 256
    timeout       = 10
    environment_variables = {
      DYNAMODB_TABLE_NAME     = "spotech-dev-main"
      CORS_ORIGIN             = "https://d3n25hf9bvh9rw.cloudfront.net"
      POWERTOOLS_SERVICE_NAME = "spotech-vendors-api"
      LOG_LEVEL               = "INFO"
    }
    tracing_config = { mode = "Active" }
    specifictags   = {}
  }

  # Teams API - GET /teams, GET /teams/{id}
  teams-api = {
    function_name = "spotech-dev-teams-api"
    source_dir    = "../backend/src"
    output_path   = ".terraform/builds/teams-api.zip"
    handler       = "handlers.teams_api.lambda_handler"
    runtime       = "python3.12"
    memory_size   = 256
    timeout       = 10
    environment_variables = {
      DYNAMODB_TABLE_NAME     = "spotech-dev-main"
      CORS_ORIGIN             = "https://d3n25hf9bvh9rw.cloudfront.net"
      POWERTOOLS_SERVICE_NAME = "spotech-teams-api"
      LOG_LEVEL               = "INFO"
    }
    tracing_config = { mode = "Active" }
    specifictags   = {}
  }
}

# -----------------------------------------------------------------------------
# S3 Website Configurations
# -----------------------------------------------------------------------------
s3_website_configs = {
  frontend = {
    index_document_suffix = "index.html"
    error_document_key    = "index.html"
    routing_rules         = [] # Empty for now, module handles conversion to JSON
  }
}

# -----------------------------------------------------------------------------
# S3 Encryption Configurations
# -----------------------------------------------------------------------------
s3_sse_configs = {
  frontend = {} # Uses default: AES256
  data     = {} # Uses default: AES256
  logs     = {} # Uses default: AES256
}

# -----------------------------------------------------------------------------
# S3 CORS Configurations
# -----------------------------------------------------------------------------
s3_cors_configs = {
  frontend = {
    cors_rules = [
      {
        allowed_methods = ["GET", "HEAD"]
        allowed_origins = ["*"] # Dev only! Restrict in prod
        # allowed_headers, expose_headers, max_age_seconds use defaults
      }
    ]
  }
}

# -----------------------------------------------------------------------------
# CloudFront Distributions
# -----------------------------------------------------------------------------
cloudfront_distributions = {
  frontend_cdn = {
    s3_bucket_key = "frontend" # Required - links to bucket
    purpose       = "Static Website CDN - React App"
    comment       = "Dev environment CDN for SportsTech frontend"
    specifictags = {
      Component = "CDN"
      Frontend  = "React"
    }
    # Uses all smart defaults:
    # - enabled=true, ipv6=true
    # - price_class=PriceClass_100 (cost-optimized)
    # - redirect-to-https (security)
    # - compression=true (performance)
    # - SPA routing (404/403 -> /index.html)
  }
}

# -----------------------------------------------------------------------------
# API Gateway Configuration
# -----------------------------------------------------------------------------
# HTTP API for serverless backend
# Pattern: Flattened structure allows scaling to hundreds of routes
# Integration types: AWS_PROXY (Lambda), HTTP_PROXY (external APIs)
# -----------------------------------------------------------------------------
api_gtws = {

  # Main API serving all endpoints
  main = {
    name          = "spotech-dev-api"
    protocol_type = "HTTP"
    description   = "Development API for SportsTech platform"

    # payload_format_version: "2.0" for HTTP API, "1.0" for legacy
    integrations = {

      # Integration for vendors API Lambda
      vendors-integration = {
        integration_type       = "AWS_PROXY"
        lambda_key             = "vendors-api" # Will be resolved to invoke ARN
        payload_format_version = "2.0"
        timeout_milliseconds   = 30000
        description            = "Integration with vendors Lambda"
      }

      # Integration for teams API Lambda
      teams-integration = {
        integration_type       = "AWS_PROXY"
        lambda_key             = "teams-api" # Will be resolved to invoke ARN
        payload_format_version = "2.0"
        timeout_milliseconds   = 30000
        description            = "Integration with teams Lambda"
      }

    }

    routes = {

      # Route: GET /vendors (list all vendors)
      get-vendors = {
        route_key          = "GET /vendors"
        integration_key    = "vendors-integration" # Will be resolved to target
        authorization_type = "NONE"
        api_key_required   = false
      }

      # Route: GET /vendors/{vendorId} (get specific vendor)
      get-vendor-by-id = {
        route_key          = "GET /vendors/{vendorId}"
        integration_key    = "vendors-integration" # Will be resolved to target
        authorization_type = "NONE"
        api_key_required   = false
      }

      # Route: GET /teams (list all teams)
      get-teams = {
        route_key          = "GET /teams"
        integration_key    = "teams-integration" # Will be resolved to target
        authorization_type = "NONE"
        api_key_required   = false
      }

      # Route: GET /teams/{teamId} (get specific team)
      get-team-by-id = {
        route_key          = "GET /teams/{teamId}"
        integration_key    = "teams-integration" # Will be resolved to target
        authorization_type = "NONE"
        api_key_required   = false
      }

    }

    stages = {

      dev = {
        name        = "dev"
        auto_deploy = true # Enable auto-deployment for dev
        description = "Development stage"

        # Enable CloudWatch logging for debugging
        default_route_settings = {
          detailed_metrics_enabled = true
          logging_level            = "INFO" # INFO or ERROR
          data_trace_enabled       = true
        }
      }

    }
  }

}
