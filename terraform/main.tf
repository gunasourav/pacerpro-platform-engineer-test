terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

# SNS Topic
resource "aws_sns_topic" "alerts" {
  name = "api-performance-alerts"
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = "YOUR-AMI-ID"
  instance_type = "t3.micro"
  tags = {
    Name = "web-app-server"
  }
}

# IAM Trust Policy
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda-remediation-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Least-privilege policy
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions   = ["ec2:RebootInstances"]
    resources = [aws_instance.web.arn]
  }
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "lambda_inline" {
  name   = "lambda-remediation-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# Archive / auto-zip Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdafunction"
  output_path = "${path.module}/lambda.zip"
}

# Lambda Function
resource "aws_lambda_function" "remediation" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "api-remediation"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambdafunction.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  environment {
    variables = {
      EC2_INSTANCE_ID = aws_instance.web.id
      SNS_TOPIC_ARN   = aws_sns_topic.alerts.arn
    }
  }
}

# Lambda Function URL webhook
resource "aws_lambda_function_url" "webhook" {
  function_name      = aws_lambda_function.remediation.function_name
  authorization_type = "NONE"
}

# Outputs
output "lambda_function_name" {
  value = aws_lambda_function.remediation.function_name
}

output "ec2_instance_id" {
  value = aws_instance.web.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "lambda_webhook_url" {
  value = aws_lambda_function_url.webhook.function_url
}
