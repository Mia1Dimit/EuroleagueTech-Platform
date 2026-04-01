variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm (AES256 or aws:kms)"
  type        = string
  default     = "AES256"
  
  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "Must be AES256 or aws:kms"
  }
}

variable "kms_key_id" {
  description = "KMS key ID or ARN (required if sse_algorithm is aws:kms)"
  type        = string
  default     = null
}