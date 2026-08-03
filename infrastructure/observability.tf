# ============================================================================
# Observability — SNS alerts, CloudWatch dashboard, 5XX alarm
# ============================================================================

# ── SNS alert topic ──────────────────────────────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "spotech-dev-alerts"

  tags = {
    Name        = "spotech-dev-alerts"
    ManagedBy   = "Terraform"
    Environment = var.environment
    Purpose     = "API error notifications"
  }
}

# Optional e-mail subscription — subscribe manually or add var.alert_email
# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "email"
#   endpoint  = var.alert_email
# }

# ── 5XX alarm ────────────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "spotech-dev-api-5xx"
  alarm_description   = "API Gateway returning 5XX errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiId = module.api_gtw["spotech-dev-api"].api_id
    Stage = "dev"
  }

  tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

# ── Lambda error alarms (one per function) ───────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = var.lambdas

  alarm_name          = "spotech-dev-${each.key}-errors"
  alarm_description   = "Lambda ${each.key} error rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = each.value.function_name
  }

  tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

# ── CloudWatch dashboard ──────────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "spotech-dev-platform"

  dashboard_body = jsonencode({
    widgets = [
      # API Gateway — 5XX errors
      {
        type   = "metric"
        x      = 0; y = 0; width = 12; height = 6
        properties = {
          title  = "API Gateway 5XX Errors"
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/ApiGateway", "5XXError", "ApiId", module.api_gtw["spotech-dev-api"].api_id, "Stage", "dev"]
          ]
          view = "timeSeries"
        }
      },
      # API Gateway — latency P99
      {
        type   = "metric"
        x      = 12; y = 0; width = 12; height = 6
        properties = {
          title  = "API Gateway Latency P99"
          period = 300
          stat   = "p99"
          metrics = [
            ["AWS/ApiGateway", "IntegrationLatency", "ApiId", module.api_gtw["spotech-dev-api"].api_id, "Stage", "dev"]
          ]
          view = "timeSeries"
        }
      },
      # Lambda — invocations
      {
        type   = "metric"
        x      = 0; y = 6; width = 12; height = 6
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
      # Lambda — duration P99
      {
        type   = "metric"
        x      = 12; y = 6; width = 12; height = 6
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
      # Lambda — errors
      {
        type   = "metric"
        x      = 0; y = 12; width = 12; height = 6
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
      # DynamoDB — consumed read capacity
      {
        type   = "metric"
        x      = 12; y = 12; width = 12; height = 6
        properties = {
          title  = "DynamoDB Consumed Read Capacity"
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "spotech-dev-main"]
          ]
          view = "timeSeries"
        }
      }
    ]
  })
}
