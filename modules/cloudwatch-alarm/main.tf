resource "aws_cloudwatch_metric_alarm" "cloudwatch_metric_alarm" {
  alarm_name          = var.alarm_name
  alarm_description   = var.alarm_description
  metric_name         = var.metric_name
  namespace           = var.namespace
  statistic           = var.statistic
  period              = var.period
  evaluation_periods  = var.evaluation_periods
  threshold           = var.threshold
  comparison_operator = var.comparison_operator
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  dimensions          = var.dimensions
  treat_missing_data  = var.treat_missing_data

  tags = local.merged_tags
}
