output "api_endpoint" {
  description = "The HTTP API endpoint URL"
  value       = aws_apigatewayv2_stage.default_stage.invoke_url
}