output "id" {
  description = "The website configuration id."
  value       = aws_s3_bucket_website_configuration.website_config.id
}

output "website_domain" {
  description = "Domain of the website endpoint. This is used to create Route 53 alias records."
  value       = aws_s3_bucket_website_configuration.website_config.website_domain
}

output "website_endpoint" {
  description = "Website endpoint."
  value       = aws_s3_bucket_website_configuration.website_config.website_endpoint
}