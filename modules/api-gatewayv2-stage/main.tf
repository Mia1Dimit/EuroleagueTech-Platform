resource "aws_apigatewayv2_stage" "apigatewayv2_stage" {
  api_id      = var.api_id
  name        = var.name

  auto_deploy = var.auto_deploy
  client_certificate_id = var.client_certificate_id
  deployment_id = var.deployment_id
  description = var.description
  stage_variables = var.stage_variables


  tags = local.merged_tags



  dynamic "access_log_settings" {
    for_each = var.access_log_settings != null ? [var.access_log_settings] : []
    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = access_log_settings.value.format
    }
  }

   dynamic "default_route_settings" {
    for_each = var.default_route_settings != null ? [var.default_route_settings] : []
    content {
      data_trace_enabled       = lookup(default_route_settings.value, "data_trace_enabled", null)
      detailed_metrics_enabled = lookup(default_route_settings.value, "detailed_metrics_enabled", null)
      logging_level            = lookup(default_route_settings.value, "logging_level", null)
      throttling_burst_limit   = lookup(default_route_settings.value, "throttling_burst_limit", null)
      throttling_rate_limit    = lookup(default_route_settings.value, "throttling_rate_limit", null)
    }
  }

   dynamic "route_settings" {
    for_each = var.route_settings != null ? [var.route_settings] : []
    content {
      route_key                = route_settings.value["route_key"]
      data_trace_enabled       = lookup(route_settings.value, "data_trace_enabled", null)
      detailed_metrics_enabled = lookup(route_settings.value, "detailed_metrics_enabled", null)
      logging_level            = lookup(route_settings.value, "logging_level", null)
      throttling_burst_limit   = lookup(route_settings.value, "throttling_burst_limit", null)
      throttling_rate_limit    = lookup(route_settings.value, "throttling_rate_limit", null)
    }
  }

}