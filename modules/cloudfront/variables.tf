# ============================================================================
# CloudFront Module Input Variables (Fully Reusable)
# ============================================================================

# -----------------------------------------------------------------------------
# Required S3 Origin Variables (from s3-bucket module outputs)
# -----------------------------------------------------------------------------
variable "s3_bucket_id" {
  description = "The ID (name) of the S3 bucket to use as origin"
  type        = string
}

variable "s3_regional_domain_name" {
  description = "The regional domain name of the S3 bucket (e.g., bucket.s3.eu-west-1.amazonaws.com)"
  type        = string
}

# -----------------------------------------------------------------------------
# Distribution Configuration
# -----------------------------------------------------------------------------
variable "enabled" {
  description = "Whether the CloudFront distribution is enabled"
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled for the CloudFront distribution"
  type        = bool
  default     = true
}

variable "default_root_object" {
  description = "The object that CloudFront returns when requesting the root URL"
  type        = string
  default     = "index.html"
}

variable "comment" {
  description = "Comment for the CloudFront distribution"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront price class controlling edge locations used (cost optimization)"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition = contains(
      ["PriceClass_All", "PriceClass_200", "PriceClass_100"],
      var.price_class
    )
    error_message = "Must be PriceClass_All, PriceClass_200, or PriceClass_100"
  }
}

# -----------------------------------------------------------------------------
# Cache Behavior Configuration
# -----------------------------------------------------------------------------
variable "viewer_protocol_policy" {
  description = "Protocol viewers can use (allow-all, redirect-to-https, https-only)"
  type        = string
  default     = "redirect-to-https"

  validation {
    condition     = contains(["allow-all", "redirect-to-https", "https-only"], var.viewer_protocol_policy)
    error_message = "Must be allow-all, redirect-to-https, or https-only"
  }
}

variable "allowed_methods" {
  description = "HTTP methods CloudFront processes and forwards"
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "cached_methods" {
  description = "HTTP methods for which CloudFront caches responses"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cache_policy_id" {
  description = "ID of the cache policy (AWS Managed or custom)"
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
}

variable "compress" {
  description = "Whether CloudFront compresses content (Gzip/Brotli)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Custom Error Responses (for SPA support)
# -----------------------------------------------------------------------------
variable "custom_error_responses" {
  description = "Custom error responses for SPA routing or error pages"
  type = list(object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = number
  }))
  default = [
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
  ]
}

# -----------------------------------------------------------------------------
# Geographic Restrictions
# -----------------------------------------------------------------------------
variable "geo_restriction_type" {
  description = "Method to restrict content by country (none, whitelist, blacklist)"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Must be none, whitelist, or blacklist"
  }
}

variable "geo_restriction_locations" {
  description = "ISO 3166-1-alpha-2 country codes for geo restriction"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# SSL/TLS Certificate Configuration
# -----------------------------------------------------------------------------
variable "cloudfront_default_certificate" {
  description = "Use CloudFront default certificate (*.cloudfront.net)"
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate (required if cloudfront_default_certificate = false)"
  type        = string
  default     = null
}

variable "ssl_support_method" {
  description = "How CloudFront serves HTTPS (sni-only or vip)"
  type        = string
  default     = "sni-only"

  validation {
    condition     = contains(["sni-only", "vip"], var.ssl_support_method)
    error_message = "Must be sni-only or vip"
  }
}

variable "minimum_protocol_version" {
  description = "Minimum TLS protocol version"
  type        = string
  default     = "TLSv1.2_2021"
}

# -----------------------------------------------------------------------------
# Tagging
# -----------------------------------------------------------------------------
variable "environment" {
  type        = string
  description = "Environment Tag"
}

variable "applicationid" {
  type        = string
  description = "Application_ID Tag"
}

variable "applicationname" {
  type        = string
  description = "Application_Name Tag"
}

variable "name" {
  description = "Name of the CloudFront distribution"
  type        = string
}

variable "specifictags" {
  type        = map(string)
  description = "Specific tags for the resource"
  default     = {}
}

variable "purpose" {
  type        = string
  description = "Purpose of the CloudFront distribution"
  default     = "Static Website CDN"
}

# -----------------------------------------------------------------------------
# Locals - Tag Merging Strategy
# -----------------------------------------------------------------------------
locals {
  common_tags = {
    Application_ID   = var.applicationid
    Application_Name = var.applicationname
    Environment      = var.environment
    Name             = var.name
    Module           = "cloudfront"
    Purpose          = var.purpose
  }
  merged_tags = merge(local.common_tags, var.specifictags)
}
