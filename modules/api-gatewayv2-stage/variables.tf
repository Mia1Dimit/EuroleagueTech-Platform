locals {
  common_tags = {
    Application_ID    = var.applicationid
    Application_Name  = var.applicationname
    Environment       = var.environment
  }
  merged_tags = merge(local.common_tags, var.specifictags)
}

variable "api_id" {
  description = "The API identifier."
  type        = string
}

variable "auto_deploy" {
  description = "Whether updates to an API deployment should be automatically deployed to this stage."
  type        = bool
  default     = false
}

variable "client_certificate_id" {
  description = "The identifier of a client certificate for the stage. Supported only for WebSocket APIs"
  type        = string
  default     = null
}

variable "deployment_id" {
  description = "Deployment identifier of the stage."
  type        = string
  default     = null
}

variable "description" {
  description = "The description for the API stage."
  type        = string
  default     = null
}

variable "stage_variables" {
  description = "A map that defines the stage variables for the stage."
  type        = map(string)
  default     = {}
}

variable "access_log_settings" {
  description = "Settings for logging access in this stage."
  type = object({
    destination_arn = string
    format          = string
  })
  default = null
}

variable "default_route_settings" {
  description = "Default route settings for the stage."
  type = object({
    data_trace_enabled       = optional(bool)
    detailed_metrics_enabled = optional(bool)
    logging_level            = optional(string)
    throttling_burst_limit   = optional(number)
    throttling_rate_limit    = optional(number)
  })
  default = null
}

variable "route_settings" {
  description = "Route settings for the stage."
  type = object({
    route_key                = string
    data_trace_enabled       = optional(bool)
    detailed_metrics_enabled = optional(bool)
    logging_level            = optional(string)
    throttling_burst_limit   = optional(number)
    throttling_rate_limit    = optional(number)
  })
  default = null
}

variable "specifictags" {
    type = map(string)
    description = "Specific tags for the resource"
}

variable "environment" {
  type = string
  description = "Environment Tag"
}

variable "applicationid" {
  type = string
  description = "Application_ID Tag"
}

variable "applicationname" {
  type = string
  description = "Application_Name Tag"
}

variable "name" {
  description = "Name of the stage. Must be between 1 and 128 characters in length."
  type        = string
}