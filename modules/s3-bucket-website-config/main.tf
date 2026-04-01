resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = var.bucket_name
  index_document {
    suffix = var.index_document_suffix
  }
  error_document {
    key = var.error_document_key
  }
  # Convert list to JSON string (AWS S3 API requires JSON format)
  # If list is empty, omit routing_rules entirely (null = not set)
  routing_rules = length(var.routing_rules) > 0 ? jsonencode(var.routing_rules) : null
}