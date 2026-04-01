# ============================================================================
# S3 Bucket Resources - Main Bucket Creation
# ============================================================================
module "s3_bucket" {
  for_each              = var.s3_buckets
  source                = "../modules/s3-bucket"
  bucket_name           = each.value["bucket_name"]
  purpose               = each.value["purpose"]
  force_destroy         = each.value["force_destroy"]
  blockpublicacls       = each.value["blockpublicacls"]
  blockpublicpolicy     = each.value["blockpublicpolicy"]
  ignorepublicacls      = each.value["ignorepublicacls"]
  restrictpublicbuckets = each.value["restrictpublicbuckets"]
  enable_versioning     = each.value["enable_versioning"]
  object_ownership      = each.value["object_ownership"]
  rules                 = each.value["rules"]
  environment           = var.environment
  applicationid         = var.applicationid
  applicationname       = var.applicationname
  name                  = each.key
  specifictags          = each.value["specifictags"]
}

# ============================================================================
# S3 Website Configuration
# ============================================================================
module "s3_website_config" {
  for_each              = var.s3_website_configs
  source                = "../modules/s3-bucket-website-config"
  bucket_name           = module.s3_bucket[each.key].s3-id
  index_document_suffix = each.value["index_document_suffix"]
  error_document_key    = each.value["error_document_key"]
  routing_rules         = each.value["routing_rules"]
  depends_on            = [module.s3_bucket]
}

# ============================================================================
# S3 Server-Side Encryption Configuration
# ============================================================================
module "s3_sse_config" {
  for_each      = var.s3_sse_configs
  source        = "../modules/s3-bucket-sse-config"
  bucket_name   = module.s3_bucket[each.key].s3-id
  sse_algorithm = each.value["sse_algorithm"]
  kms_key_id    = each.value["kms_key_id"]
  depends_on    = [module.s3_bucket]
}

# ============================================================================
# S3 CORS Configuration
# ============================================================================
module "s3_cors_config" {
  for_each              = var.s3_cors_configs
  source                = "../modules/s3-bucket-cors-config"
  bucket_name           = module.s3_bucket[each.key].s3-id
  expected_bucket_owner = each.value["expected_bucket_owner"]
  cors_rules            = each.value["cors_rules"]
  depends_on            = [module.s3_bucket]
}