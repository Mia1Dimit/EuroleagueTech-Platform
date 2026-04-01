resource "aws_cloudwatch_log_group" "log_group" {
  name              = var.name
  log_group_class   = var.log_group_class
  retention_in_days = var.retention_in_days
  tags              = local.merged_tags
}