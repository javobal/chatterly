output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.chatterly.function_name
}
