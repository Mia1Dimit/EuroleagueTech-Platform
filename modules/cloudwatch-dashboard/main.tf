resource "aws_cloudwatch_dashboard" "cloudwatch_dashboard" {
  dashboard_name = var.dashboard_name
  dashboard_body = var.dashboard_body
}
