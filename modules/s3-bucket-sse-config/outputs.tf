output "s3_bucket_sse_config_id" {
  description = "The ID of the S3 bucket server-side encryption configuration."
  value       = aws_s3_bucket_server_side_encryption_configuration.sse_config.id
}