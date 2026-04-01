variable "bucket_name" {
  description = "Name of the bucket to which to apply the policy."
  type        = string
}

variable "policy" {
  description = "Text of the policy. Although this is a bucket policy rather than an IAM policy, the aws_iam_policy_document data source may be used, so long as it specifies a principal. Note: Bucket policies are limited to 20 KB in size."
  type        = string
}