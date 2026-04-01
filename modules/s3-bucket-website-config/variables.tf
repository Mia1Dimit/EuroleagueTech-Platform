variable "bucket_name" {
  description = "The name of the bucket."
  type        = string
}

variable "index_document_suffix" {
  description = "The suffix that is appended to a request that is for a directory on the website endpoint bucket to identify the object that is returned from the index document."
  type        = string
}

variable "error_document_key" {
  description = "The object key name to use when a 4XX class error occurs."
  type        = string
}

variable "routing_rules" {
  description = "List of routing rule objects"
  type = list(object({
    condition = object({
      http_error_code_returned_equals = optional(string)
      key_prefix_equals               = optional(string)
    })
    redirect = object({
      host_name               = optional(string)
      http_redirect_code      = optional(string)
      protocol                = optional(string)
      replace_key_prefix_with = optional(string)
      replace_key_with        = optional(string)
    })
  }))
  default = []
}


