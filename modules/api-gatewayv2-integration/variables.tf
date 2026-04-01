variable "api_id" {
  description = "The API identifier."
  type        = string
}

variable "integration_type" {
  description = "The integration type of an integration. Valid values: AWS, AWS_PROXY, HTTP, HTTP_PROXY, MOCK."
  type        = string
}

variable "connection_id" {
  description = "The ID of the VPC link for a private integration."
  type        = string
  default     = null
}

variable "connection_type" {
  description = "The type of the network connection to the integration endpoint. Valid values: INTERNET, VPC_LINK."
  type        = string
  default     = null
}

variable "content_handling_strategy" {
  description = "How to handle response payload content type conversions. Valid values: CONVERT_TO_BINARY, CONVERT_TO_TEXT."
  type        = string
  default     = null
}

variable "credentials_arn" {
  description = "The credentials ARN for the integration."
  type        = string
  default     = null
}

variable "description" {
  description = "The description of the integration."
  type        = string
  default     = null
}

variable "integration_method" {
  description = "The integration's HTTP method. Must be specified if `integration_type` is not `MOCK`."
  type        = string
  default     = null
}

variable "integration_subtype" {
  description = "AWS service action to invoke. Supported only for HTTP APIs when integration_type is AWS_PROXY. Must be between 1 and 128 characters in length."
  type        = string
  default     = null
}

variable "integration_uri" {
  description = "URI of the Lambda function for a Lambda proxy integration, when integration_type is AWS_PROXY. For an HTTP integration, specify a fully-qualified URL. For an HTTP API private integration, specify the ARN of an Application Load Balancer listener, Network Load Balancer listener, or AWS Cloud Map service."
  type        = string
  default     = null
}

variable "passthrough_behavior" {
  description = "The passthrough behavior of the integration. Supported only for WebSocket APIs. Valid values: `WHEN_NO_MATCH`, `WHEN_NO_TEMPLATES`, `NEVER`."
  type        = string
  default     = null
}

variable "payload_format_version" {
  description = "The format of the payload sent to an integration. Valid values: `1.0`, `2.0`."
  type        = string
  default     = null
}

variable "request_parameters" {
  description = "A map of request parameters that can be specified for backend integrations."
  type        = map(string)
  default     = null
}

variable "request_templates" {
  description = "Supported only for WebSocket APIs. A map of Velocity templates that are applied on the request payload based on the value of the Content-Type header sent by the client."
  type        = map(string)
  default     = null
}

variable "response_parameters" {
  description = "Supported only for HTTP APIs. A list of objects with response parameters that can be specified for backend integrations."
  type = list(object({
    mappings    = map(string)
    status_code = string
  }))
  default     = []
}

variable "template_selection_expression" {
  description = "The template selection expression for the integration."
  type        = string
  default     = null
}

variable "timeout_milliseconds" {
  description = "Custom timeout between 50 and 30,000 milliseconds for HTTP APIs."
  type        = number
  default     = null
}

variable "tls_config" {
  description = "The TLS configuration for a private integration."
  type = object({
    server_name_to_verify = optional(string)
  })
  default     = null
}