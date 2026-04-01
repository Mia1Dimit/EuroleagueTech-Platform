variable "api_id" {
  type        = string
  description = "API identifier."
}

variable "route_key" {
  type        = string
  description = "Route key for the route. For HTTP APIs, can be $default or METHOD /path."
}

variable "api_key_required" {
  type        = bool
  default     = false
  description = "Boolean whether an API key is required for the route. Supported only for WebSocket APIs."
}

variable "authorization_scopes" {
  type        = list(string)
  default     = null
  description = "Authorization scopes supported by this route. Used with JWT authorizers."
}

variable "authorization_type" {
  type        = string
  default     = "NONE"
  description = "Authorization type: NONE, AWS_IAM, JWT, CUSTOM."
}

variable "authorizer_id" {
  type        = string
  default     = null
  description = "Identifier of the aws_apigatewayv2_authorizer resource to associate."
}

variable "model_selection_expression" {
  type        = string
  default     = null
  description = "Model selection expression for the route (WebSocket only)."
}

variable "operation_name" {
  type        = string
  default     = null
  description = "Operation name for the route (1–64 chars)."
}

variable "request_models" {
  type        = map(string)
  default     = null
  description = "Request models for the route (WebSocket only)."
}

variable "request_parameters" {
  type = list(object({
    request_parameter_key = string
    required              = bool
  }))
  default     = null
  description = "List of request parameters for the route (WebSocket only)."
}

variable "route_response_selection_expression" {
  type        = string
  default     = null
  description = "Route response selection expression (WebSocket only)."
}

variable "target" {
  type        = string
  default     = null
  description = "Target for the route, of the form integrations/IntegrationID."
}
