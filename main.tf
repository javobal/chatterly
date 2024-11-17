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

