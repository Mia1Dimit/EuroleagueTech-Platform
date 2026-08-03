resource "aws_sns_topic" "sns_topic" {
  name         = var.fifo_topic ? "${var.name}.fifo" : var.name
  display_name = var.display_name

  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null
  archive_policy              = var.fifo_topic ? var.archive_policy : null

  kms_master_key_id = var.kms_master_key_id
  delivery_policy   = var.delivery_policy
  policy            = var.policy

  tracing_config    = var.tracing_config
  signature_version = var.signature_version

  tags = local.merged_tags
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  count = var.topic_policy != null ? 1 : 0

  arn    = aws_sns_topic.sns_topic.arn
  policy = var.topic_policy
}
