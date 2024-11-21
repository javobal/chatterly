output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.chatterly.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.gw_dev_stage.invoke_url
}

output "record_name" {
  description = "Custom Route 53 Record"
  value = aws_route53_record.chatterly_api.name
}
