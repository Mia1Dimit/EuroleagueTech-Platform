output "id" {
  description = "The integration ID."
  value       = aws_apigatewayv2_integration.apigatewayv2_integration.id
}

output "integration_response_selection_expression" {
  description = "The integration response selection expression for the integration."
  value       = aws_apigatewayv2_integration.apigatewayv2_integration.integration_response_selection_expression
}
