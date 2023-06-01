terraform {
  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
  access_key = "AKIA4L5VVT7A5W4Z7FNS"
  secret_key = "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"
}

locals {
  function_get_obituaries= "get-obituaries-30163348"
  function_create_obituaries  = "create-obituaries-30163348"

  handler_get_obituaries = "main.lambda_handler"
  handler_create_obituaries = "main.lambda_handler"

  artifact_get_obituaries = "${local.function_get_obituaries}/artifact.zip"
  artifact_create_obituaries = "${local.function_create_obituaries}/artifact.zip"
}

data "archive_file" "lambda_zip_get_obituaries" {
  type = "zip"
  source_file = "../functions/get-obituaries/main.py"
  output_path = "${local.function_get_obituaries}/artifact.zip"
}

data "archive_file" "lambda_zip_create_obituaries" {
  type = "zip"
  source_file = "../functions/create-obituaries/main.py"
  output_path = "${local.function_create_obituaries}/artifact.zip"
}


# two lambda functions w/ function url
resource "aws_lambda_function" "get_obituaries_lambda" {
  filename = data.archive_file.lambda_zip_get_obituaries.output_path
  role          = aws_iam_role.lambda_get_obituaries.arn
  function_name = local.function_get_obituaries
  handler       = local.handler_get_obituaries
  source_code_hash = data.archive_file.lambda_zip_get_obituaries.output_base64sha256

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
}

resource "aws_lambda_function" "create_obituaries_lambda" {
  filename = data.archive_file.lambda_zip_create_obituaries.output_path
  role          = aws_iam_role.lambda_create_obituaries.arn
  function_name = local.function_create_obituaries
  handler       = local.handler_create_obituaries
  source_code_hash = data.archive_file.lambda_zip_create_obituaries.output_base64sha256

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
}

#lambda function URLs
resource  "aws_lambda_function_url" "get_obituaries_function_url" {
  function_name = aws_lambda_function.get_obituaries_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins = ["*"]
    allow_methods = ["GET"]
    allow_headers = ["*"]
    expose_headers = ["Keep-alive", "date"]
  }
}

resource  "aws_lambda_function_url" "create_obituaries_function_url" {
  function_name = aws_lambda_function.create_obituaries_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins = ["*"]
    allow_methods = ["POST", "PUT"]
    allow_headers = ["*"]
    expose_headers = ["Keep-alive", "date"]
  }
}



# one dynamodb table

resource "aws_dynamodb_table" "obituaries" {
  name           = "obituaries"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }

  attribute {
    name = "description"
    type = "S"
  }

  global_secondary_index {
    name               = "name-index"
    hash_key           = "name"
    projection_type    = "ALL"
    write_capacity     = 1
    read_capacity      = 1
  }

  global_secondary_index {
    name               = "description-index"
    hash_key           = "description"
    projection_type    = "ALL"
    write_capacity     = 1
    read_capacity      = 1
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


output "get_obituaries_function_url" {
  value = aws_lambda_function_url.get_obituaries_function_url.function_url
}

output "create_obituaries_function_url" {
  value = aws_lambda_function_url.create_obituaries_function_url.function_url
}



# roles and policies as needed
resource "aws_iam_role" "lambda_get_obituaries" {
  name               = "iam-for-lambda-${local.function_get_obituaries}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_create_obituaries" {
  name               = "iam-for-lambda-${local.function_create_obituaries}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "get_obituaries_logs" {
  name        = "lambda-logging-${local.function_get_obituaries}"
  description = "IAM policy for logging from a lambda for get obituaries"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:Query"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.obituaries.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "create_obituaries_logs" {
  name        = "lambda-logging-${local.function_create_obituaries}"
  description = "IAM policy for logging from a lambda for create obituaries"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:Query"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.obituaries.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "dynamodb_access" {
  name = "dynamodb_access_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:ca-central-1:850247655361:table/obituaries"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_access_policy_attachment" {
  role       = aws_iam_role.lambda_get_obituaries.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs_get" {
  role       = aws_iam_role.lambda_get_obituaries.name
  policy_arn = aws_iam_policy.get_obituaries_logs.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs_create" {
  role       = aws_iam_role.lambda_create_obituaries.name
  policy_arn = aws_iam_policy.create_obituaries_logs.arn
}
# step functions (if you're going for the bonus marks)
