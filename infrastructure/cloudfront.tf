# ============================================================================
# CloudFront Distribution
# ============================================================================
module "cloudfront" {
  for_each                       = var.cloudfront_distributions
  source                         = "../modules/cloudfront"
  s3_bucket_id                   = module.s3_bucket[each.value["s3_bucket_key"]].s3-id
  s3_regional_domain_name        = module.s3_bucket[each.value["s3_bucket_key"]].bucket_regional_domain_name
  purpose                        = each.value["purpose"]
  enabled                        = each.value["enabled"]
  is_ipv6_enabled                = each.value["is_ipv6_enabled"]
  default_root_object            = each.value["default_root_object"]
  comment                        = each.value["comment"]
  price_class                    = each.value["price_class"]
  viewer_protocol_policy         = each.value["viewer_protocol_policy"]
  allowed_methods                = each.value["allowed_methods"]
  cached_methods                 = each.value["cached_methods"]
  cache_policy_id                = each.value["cache_policy_id"]
  compress                       = each.value["compress"]
  custom_error_responses         = each.value["custom_error_responses"]
  geo_restriction_type           = each.value["geo_restriction_type"]
  geo_restriction_locations      = each.value["geo_restriction_locations"]
  cloudfront_default_certificate = each.value["cloudfront_default_certificate"]
  acm_certificate_arn            = each.value["acm_certificate_arn"]
  ssl_support_method             = each.value["ssl_support_method"]
  minimum_protocol_version       = each.value["minimum_protocol_version"]
  environment                    = var.environment
  applicationid                  = var.applicationid
  applicationname                = var.applicationname
  name                           = each.key
  specifictags                   = each.value["specifictags"]
  depends_on                     = [module.s3_bucket]
}

# ============================================================================
# S3 Bucket Policy - Allow CloudFront OAC Access
# ============================================================================
module "s3_bucket_policy_cloudfront" {
  for_each    = var.cloudfront_distributions
  source      = "../modules/s3-bucket-policy"
  bucket_name = module.s3_bucket[each.value["s3_bucket_key"]].s3-id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontOAC"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${module.s3_bucket[each.value["s3_bucket_key"]].s3-arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = module.cloudfront[each.key].distribution_arn
        }
      }
    }]
  })
  depends_on = [module.cloudfront]
}