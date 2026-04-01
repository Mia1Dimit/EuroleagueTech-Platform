# ============================================================================
# CloudFront Module Outputs
# ============================================================================

output "distribution_id" {
  description = "The ID of the CloudFront distribution (for cache invalidations)"
  value       = aws_cloudfront_distribution.cdn.id
}

output "distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.arn
}

output "domain_name" {
  description = "The domain name of the CloudFront distribution (e.g., d1234abcd.cloudfront.net)"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID (for creating Route53 alias records in Phase 3)"
  value       = aws_cloudfront_distribution.cdn.hosted_zone_id
}

output "oac_id" {
  description = "The ID of the Origin Access Control (needed for S3 bucket policy)"
  value       = aws_cloudfront_origin_access_control.s3_oac.id
}

output "oac_arn" {
  description = "The ARN of the Origin Access Control"
  value       = aws_cloudfront_origin_access_control.s3_oac.arn
}

