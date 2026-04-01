resource "aws_apigatewayv2_api" "apigatewayv2_api" {
  name                       = var.name
  protocol_type              = var.protocol_type

  api_key_selection_expression = var.api_key_selection_expression
  credentials_arn              = var.credentials_arn
  description                  = var.description
  disable_execute_api_endpoint = var.disable_execute_api_endpoint
  route_key                    = var.route_key
  route_selection_expression   = var.route_selection_expression
  target                       = var.target
  version                      = var.api_version
  body                         = var.body
  fail_on_warnings             = var.fail_on_warnings

  dynamic "cors_configuration" {
    for_each = var.cors_configuration == null ? [] : [var.cors_configuration]
    content {
      allow_credentials = lookup(cors_configuration.value, "allow_credentials", null)
      allow_headers     = lookup(cors_configuration.value, "allow_headers", null)
      allow_methods     = lookup(cors_configuration.value, "allow_methods", null)
      allow_origins     = lookup(cors_configuration.value, "allow_origins", null)
      expose_headers    = lookup(cors_configuration.value, "expose_headers", null)
      max_age           = lookup(cors_configuration.value, "max_age", null)
    }
  }

  tags = local.merged_tags
}

