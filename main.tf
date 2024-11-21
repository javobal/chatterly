# Route 53 Zone -> API Gateway -> Lambda 

terraform { 
  cloud { 
    
    organization = "javobal" 

    workspaces { 
      name = "dev" 
    } 
  } 

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "javobal"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment     = "Dev"
      App         = "chatterly"
      Deployment = "tf"
    }
  }

}

##### Zip -> S3 Bucket

data "archive_file" "lambda_archive" {
  type = "zip"
  output_file_mode = "0666"
  source_dir  = "${path.module}/chatterly-msg/dist"
  output_path = "${path.module}/chatterly-msg/chatterly-msg.zip"
}

resource "aws_s3_bucket" "lambda-chatterly-msg" {
  bucket_prefix = "lambda-chatterly-msg"
}

resource "aws_s3_object" "lambda_chatterly_msg_zip" {
  bucket = aws_s3_bucket.lambda-chatterly-msg.id

  key    = "chatterly-msg.zip"
  source = data.archive_file.lambda_archive.output_path

  etag = filemd5(data.archive_file.lambda_archive.output_path)
}

########### LAMBDA ################################################

resource "aws_lambda_function" "chatterly" {
  function_name = "chatterly-service"

  s3_bucket = aws_s3_bucket.lambda-chatterly-msg.id
  s3_key    = aws_s3_object.lambda_chatterly_msg_zip.key

  runtime = "nodejs20.x"
  handler = "index.handler"

  source_code_hash = data.archive_file.lambda_archive.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "chatterly" {
  name = "/aws/lambda/${aws_lambda_function.chatterly.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

### API GATEWAY ##########################################################################

resource "aws_apigatewayv2_api" "api_gw" {
  name          = "chatterly"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "gw_dev_stage" {
  api_id = aws_apigatewayv2_api.api_gw.id

  name        = "dev_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.api_gw.name}"

  retention_in_days = 30
}

resource "aws_apigatewayv2_integration" "chatterly" {
  api_id = aws_apigatewayv2_api.api_gw.id

  integration_uri    = aws_lambda_function.chatterly.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "chatterly" {
  api_id = aws_apigatewayv2_api.api_gw.id

  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.chatterly.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatterly.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_gw.execution_arn}/*/*"
}

#### Route 53 Domain Mapping

resource "aws_apigatewayv2_domain_name" "chatterly_api" {
  domain_name = "server.chatterly.javobal.com"

  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.chatterly.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "chatterly_api" {
  api_id      = aws_apigatewayv2_api.api_gw.id
  domain_name = aws_apigatewayv2_domain_name.chatterly_api.id
  stage       = aws_apigatewayv2_stage.gw_dev_stage.id
}

# Find a certificate that is issued
data "aws_acm_certificate" "chatterly" {
  domain   = "chatterly.javobal.com"
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "chatterly" {
  name         = "chatterly.javobal.com"
}

# Alias Record
resource "aws_route53_record" "chatterly_api" {
  zone_id = data.aws_route53_zone.chatterly.zone_id
  name    = "server.${data.aws_route53_zone.chatterly.name}"
  type    = "A"

  # aws_apigatewayv2_domain_name / target_domain_name == API Gateway Domain Name (Console)
  # alias name = api_gateway_domain target_domain_name
  alias {
    name                   = aws_apigatewayv2_domain_name.chatterly_api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.chatterly_api.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = true
  }
}



