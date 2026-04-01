output "route_id" {
  description = "The ID of the API Gateway v2 route."
  value       = aws_apigatewayv2_route.apigatewayv2_route.id
}