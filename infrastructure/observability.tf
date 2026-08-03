# ============================================================================
# Observability — SNS alerts, CloudWatch alarms, dashboard
# All resources via modules (copied from Terraform-modules registry)
# ============================================================================

# ── SNS alert topic ──────────────────────────────────────────────────────────
module "sns_alerts" {
  source = "../modules/sns-topic"

  name    = "spotech-dev-alerts"
  purpose = "API and Lambda error notifications"

  applicationid   = var.applicationid
  applicationname = var.applicationname
  environment     = var.environment
  specifictags    = {}
}

# ── API Gateway 5XX alarm ─────────────────────────────────────────────────────
module "alarm_api_5xx" {
  source = "../modules/cloudwatch-alarm"

  alarm_name          = "spotech-dev-api-5xx"
  alarm_description   = "API Gateway returning 5XX errors"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [module.sns_alerts.topic_arn]
  ok_actions          = [module.sns_alerts.topic_arn]
  dimensions = {
    ApiId = module.api_definitions["main"].api_id
    Stage = "dev"
  }

  applicationid   = var.applicationid
  applicationname = var.applicationname
  environment     = var.environment
  specifictags    = {}
}

# ── Lambda error alarms ───────────────────────────────────────────────────────
module "alarm_vendors_api_errors" {
  source = "../modules/cloudwatch-alarm"

  alarm_name          = "spotech-dev-vendors-api-errors"
  alarm_description   = "Lambda vendors-api error count"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [module.sns_alerts.topic_arn]
  dimensions          = { FunctionName = "spotech-dev-vendors-api" }

  applicationid   = var.applicationid
  applicationname = var.applicationname
  environment     = var.environment
  specifictags    = {}
}

module "alarm_teams_api_errors" {
  source = "../modules/cloudwatch-alarm"

  alarm_name          = "spotech-dev-teams-api-errors"
  alarm_description   = "Lambda teams-api error count"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [module.sns_alerts.topic_arn]
  dimensions          = { FunctionName = "spotech-dev-teams-api" }

  applicationid   = var.applicationid
  applicationname = var.applicationname
  environment     = var.environment
  specifictags    = {}
}

# ── CloudWatch dashboard ──────────────────────────────────────────────────────
module "dashboard_main" {
  source = "../modules/cloudwatch-dashboard"

  dashboard_name = "spotech-dev-platform"
  name           = "spotech-dev-platform"
  purpose        = "Operational observability for the SportsTech platform"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "API Gateway 5XX Errors"
          period = 300
          stat   = "Sum"
          metrics = [["AWS/ApiGateway", "5XXError", "ApiId", module.api_definitions["main"].api_id, "Stage", "dev"]]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "API Gateway Latency P99 (ms)"
          period = 300
          stat   = "p99"
          metrics = [["AWS/ApiGateway", "IntegrationLatency", "ApiId", module.api_definitions["main"].api_id, "Stage", "dev"]]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Invocations"
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "spotech-dev-vendors-api"],
            ["AWS/Lambda", "Invocations", "FunctionName", "spotech-dev-teams-api"]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Duration P99 (ms)"
          period = 300
          stat   = "p99"
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "spotech-dev-vendors-api"],
            ["AWS/Lambda", "Duration", "FunctionName", "spotech-dev-teams-api"]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Errors"
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", "spotech-dev-vendors-api"],
            ["AWS/Lambda", "Errors", "FunctionName", "spotech-dev-teams-api"]
          ]
          view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "DynamoDB Consumed Read Capacity"
          period = 300
          stat   = "Sum"
          metrics = [["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "spotech-dev-main"]]
          view = "timeSeries"
        }
      }
    ]
  })

  applicationid   = var.applicationid
  applicationname = var.applicationname
  environment     = var.environment
  specifictags    = {}
}

