variable "bucket_name" {
  description = "The name of the bucket."
  type        = string
}

variable "expected_bucket_owner" {
  description = "Account ID of the expected bucket owner."
  type    = string
  default = null
}

variable "cors_rules" {
  description = "List of CORS rules."
  type = list(object({
    allowed_methods = list(string)
    allowed_origins = list(string)
    allowed_headers = optional(list(string))
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
    id              = optional(string)
  }))
}