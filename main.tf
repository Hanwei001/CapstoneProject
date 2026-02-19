terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = var.aws_region
}


# Create VPC, Public Subnet, Private subnet
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "myVPC"
  }
}

resource "aws_subnet" "PublicSubnet" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.0.0/26"

  tags = {
    Name = "PublicSubnet"
  }
}

# resource "aws_subnet" "PrivateSubnet" {
#   vpc_id     = aws_vpc.myVPC.id
#   cidr_block = "10.0.0.64/26"

#   tags = {
#     Name = "PrivateSubnet"
#   }
# }

# Create NAT gateway, Internet Gateway

# resource "aws_nat_gateway" "myNAT_gw" {
#   allocation_id = aws_eip.nat_eip.id
#   subnet_id     = aws_subnet.PublicSubnet.id

#   tags = {
#     Name = "myNAT gw"
#   }
# }

resource "aws_internet_gateway" "myInternet_gw" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myInternet gw"
  }
} 

# Create Route tables

resource "aws_route_table" "publicRouteTable" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myInternet_gw.id
  }

  tags = {
    Name = "public RT"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.PublicSubnet.id
  route_table_id = aws_route_table.publicRouteTable.id
}

# resource "aws_route_table" "privateRouteTable" {
#   vpc_id = aws_vpc.myVPC.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.myNAT_gw.id
#   }

#   tags = {
#     Name = "private RT"
#   }
# }

# resource "aws_route_table_association" "b" {
#   subnet_id      = aws_subnet.PrivateSubnet.id
#   route_table_id = aws_route_table.privateRouteTable.id
# }

# Create Web Server Security Group

resource "aws_security_group" "webServer_SG" {
  name        = "webServer SG"
  description = "Allow http inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "WebServer SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_HTTP_ipv4" {
  security_group_id = aws_security_group.webServer_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.webServer_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH" {
  security_group_id = aws_security_group.webServer_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Create EC2 instance for web server
resource "aws_instance" "WebServer" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id = aws_subnet.PublicSubnet.id
  vpc_security_group_ids = [aws_security_group.webServer_SG.id]  
  associate_public_ip_address = true
  key_name = var.key_name
  
  user_data = replace(
    file("userdata.sh"), 
    "INSERT_API_URL_HERE", 
    aws_apigatewayv2_stage.default_stage.invoke_url
  )
   
  tags = {
    Name = "Web Server"
  }
} 

# #Create S3 bucket
# resource "aws_s3_bucket" "myS3bucket" {
#   bucket = "mys3bucket-seaside-vacation-adviser-4622096"
# }

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

output "api_endpoint" {
  description = "The HTTP API endpoint URL"
  value       = aws_apigatewayv2_stage.default_stage.invoke_url
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