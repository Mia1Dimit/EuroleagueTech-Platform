output "topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.sns_topic.arn
}

output "topic_id" {
  description = "ID of the SNS topic (same as ARN)"
  value       = aws_sns_topic.sns_topic.id
}

output "topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.sns_topic.name
}

output "topic_owner" {
  description = "AWS account ID of the SNS topic owner"
  value       = aws_sns_topic.sns_topic.owner
}
