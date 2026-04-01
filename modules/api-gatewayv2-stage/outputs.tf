output "id" {
  description = "The stage identifier."
  value       = aws_apigatewayv2_stage.apigatewayv2_stage.id
}

output "arn" {
  description = "The ARN of the stage."
  value       = aws_apigatewayv2_stage.apigatewayv2_stage.arn
}

output "execution_arn" {
  description = "The ARN of the stage for invoking the API. To be used in permission policies."
  value       = aws_apigatewayv2_stage.apigatewayv2_stage.execution_arn
}

output "invoke_url" {
  description = "The URL to invoke the API pointing to the stage."
  value       = aws_apigatewayv2_stage.apigatewayv2_stage.invoke_url
}

output "tags_all" {
  description = "Map of tags assigned to the resource, including those inherited from the provider default_tags configuration block."
  value       = aws_apigatewayv2_stage.apigatewayv2_stage.tags_all
}
