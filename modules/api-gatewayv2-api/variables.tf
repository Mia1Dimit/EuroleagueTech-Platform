variable "name" {
  type        = string
  description = "The name of the API."
}

variable "protocol_type" {
  type        = string
  description = "The API protocol. Valid values: HTTP, WEBSOCKET."
}

variable "api_key_selection_expression" {
  type        = string
  default     = null
  description = "An API key selection expression. Defaults to $request.header.x-api-key."
}

variable "credentials_arn" {
  type        = string
  default     = null
  description = "ARN of an IAM role for the API."
}

variable "description" {
  type        = string
  default     = null
  description = "Description of the API."
}

variable "disable_execute_api_endpoint" {
  type        = bool
  default     = false
  description = "Whether to disable the default execute-api endpoint."
}

variable "route_key" {
  type        = string
  default     = null
  description = "The route key for the API."
}

variable "route_selection_expression" {
  type        = string
  default     = "$request.method $request.path"
  description = "The route selection expression for the API."
}

variable "target" {
  type        = string
  default     = null
  description = "The ARN of an integration to be used as the default route."
}

variable "api_version" {
  type        = string
  default     = null
  description = "Version identifier for the API. Must be between 1 and 64 characters in length."
}

variable "body" {
  type        = string
  default     = null
  description = "An OpenAPI specification that defines the set of routes and integrations to create as part of the HTTP APIs. Supported only for HTTP APIs."
}

variable "fail_on_warnings" {
  type        = bool
  default     = false
  description = "Whether warnings should return an error while API Gateway is creating or updating the resource using an OpenAPI specification. Defaults to false. Applicable for HTTP APIs."
}

# ---- CORS (optional object) ----
variable "cors_configuration" {
  type = object({
    allow_credentials = optional(bool)
    allow_headers     = optional(list(string))
    allow_methods     = optional(list(string))
    allow_origins     = optional(list(string))
    expose_headers    = optional(list(string))
    max_age           = optional(number)
  })
  default     = null
  description = "Optional CORS configuration object."
}

locals {
  common_tags = {
    Application_ID    = var.applicationid
    Application_Name  = var.applicationname
    Environment       = var.environment
    Name              = var.name
  }
  merged_tags = merge(local.common_tags, var.specifictags)
}

variable "specifictags" {
  type        = map(string)
  description = "Specific tags for the resource"
}

variable "environment" {
  type        = string
  description = "Environment Tag"
}

variable "applicationid" {
  type        = string
  description = "Application_ID Tag"
}

variable "applicationname" {
  type        = string
  description = "Application_Name Tag"
}
