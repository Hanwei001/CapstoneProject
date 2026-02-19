resource "aws_iam_role" "lambda_role" {
  name = "SeasideLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 权限策略：CloudWatch Logs + S3 写入
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# resource "aws_iam_role_policy" "lambda_s3_policy" {
#   name = "SeasideLambdaS3Policy"
#   role = aws_iam_role.lambda_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = ["s3:PutObject", "s3:GetObject"]
#         Resource = "${aws_s3_bucket.myS3bucket.arn}/*"
#       }
#     ]
#   })
# }


# Lambda function
resource "aws_lambda_function" "seaside_lambda" {
  function_name = "seaside-vacation-adviser"
  role          = aws_iam_role.lambda_role.arn

  runtime = "python3.11"
  handler = "SeasideLambda.lambda_handler"
  filename = "lambda.zip"

  # source_code_hash = filebase64sha256("lambda.zip")

  # environment {
  #   variables = {
  #     BUCKET_NAME = aws_s3_bucket.myS3bucket.bucket
  #   }
  # }
}

# ------------------------
# API Gateway HTTP API
# ------------------------
resource "aws_apigatewayv2_api" "seaside_api" {
  name          = "SeasideVacationAPI"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"] 
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }  
}



# Lambda integration
resource "aws_apigatewayv2_integration" "seaside_lambda_integration" {
  api_id           = aws_apigatewayv2_api.seaside_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.seaside_lambda.arn
  payload_format_version = "2.0"
}

# API route (root /)
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.seaside_api.id
  route_key = "POST /"
  target    = "integrations/${aws_apigatewayv2_integration.seaside_lambda_integration.id}"
}

# Deployment
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.seaside_api.id
  name        = "$default"
  auto_deploy = true
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.seaside_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.seaside_api.execution_arn}/*/*"
}

# ------------------------
# DynamoDB
# ------------------------
resource "aws_dynamodb_table" "seaside_history" {
  name           = "SeasideSearchHistory"
  billing_mode   = "PAY_PER_REQUEST" 
  hash_key       = "City"            
  range_key      = "Timestamp"       

  attribute {
    name = "City"
    type = "S"
  }

  attribute {
    name = "Timestamp"
    type = "S"
  }
}

# Attach DynamoDB policy to Lambda role
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "LambdaDynamoDBWritePolicy"
  description = "Allow Lambda to write to SeasideSearchHistory table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:PutItem"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.seaside_history.arn
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_role.name 
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}