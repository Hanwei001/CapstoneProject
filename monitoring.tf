# SNS definition
data "aws_ssm_parameter" "sns_email" {
  name = var.sns_email_parameter_path
}

resource "aws_sns_topic" "user_updates" {
  name = "seaside-adviser-alerts"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = data.aws_ssm_parameter.sns_email.value 
}

# # Cloudwatch monitors Lambda function to trigger the alarm 
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "SeasideLambdaErrorAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  dimensions = {
    FunctionName = aws_lambda_function.seaside_lambda.function_name
  }
}

# ---------------------------------------------------------
# AWS CloudWatch Dashboard Configuration
# Integrated view for EC2, Lambda, and DynamoDB metrics
# ---------------------------------------------------------

resource "aws_cloudwatch_dashboard" "seaside_main_dashboard" {
  dashboard_name = "SeasideAdviser-FullStack-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # 1. Dashboard Header (Text Widget)
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# 🏝️ Seaside Vacation Adviser - Full Stack Infrastructure Health"
        }
      },

      # 2. Lambda Function Performance (Left Widget)
      # Monitors execution counts and runtime failures
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.seaside_lambda.function_name, { color = "#2ca02c", label = "Total Invocations" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.seaside_lambda.function_name, { color = "#d62728", label = "Runtime Errors" }]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Traffic & Health (1m Granularity)"
        }
      },

      # 3. EC2 Web Server Utilization (Right Widget)
      # Monitors the load on the WordPress hosting instance
      {
        type   = "metric"
        x      = 12
        y      = 1
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.WebServer.id, { color = "#1f77b4", label = "CPU %" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Web Server Resource Load"
        }
      },

      # 4. DynamoDB Table Throughput (Bottom Widget)
      # Monitors read/write capacity consumption for search history
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.seaside_history.name, { label = "Read Capacity Units" }],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", aws_dynamodb_table.seaside_history.name, { label = "Write Capacity Units" }]
          ]
          period = 300
          stat   = "Sum"
          region = "eu-central-1"
          title  = "Database Persistence Traffic (DynamoDB)"
        }
      }
    ]
  })
}
# S3 bucket to store cloudtail log file
resource "aws_s3_bucket" "trail_logs" {
  bucket        = "seaside-cloudtrail-logs"
  force_destroy = true
}

# CloudTrail definition
resource "aws_cloudtrail" "main" {
  name                          = "seaside-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.trail_logs.bucket
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true
  depends_on = [aws_s3_bucket_policy.trail_policy]
}

# S3 bucket policy for CloudTrail
resource "aws_s3_bucket_policy" "trail_policy" {
  bucket = aws_s3_bucket.trail_logs.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {"Service": "cloudtrail.amazonaws.com"},
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.trail_logs.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {"Service": "cloudtrail.amazonaws.com"},
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.trail_logs.arn}/AWSLogs/*",
            "Condition": {"StringEquals": {"s3:x-amz-acl": "bucket-owner-full-control"}}
        }
    ]
}
POLICY
}