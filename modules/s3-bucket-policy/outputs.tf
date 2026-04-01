output "bucket_policy_id" {
  description = "The id of the created s3 bucket policy id"
  value       = aws_s3_bucket_policy.bucket_policy.id
}