output "api_id" {
  description = "The ID of the API Gateway v2 API."
  value       = aws_apigatewayv2_api.apigatewayv2_api.id
}

output "api_arn" {
  description = "The ARN of the API Gateway v2 API."
  value       = aws_apigatewayv2_api.apigatewayv2_api.arn
}

output "api_endpoint" {
  description = "The URI of the API (base URL without stage)."
  value       = aws_apigatewayv2_api.apigatewayv2_api.api_endpoint
}