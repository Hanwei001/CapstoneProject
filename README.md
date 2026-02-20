# Seaside Vacation Adviser - Full-Stack AWS Serverless Project

A modern, cloud-native web application that provides historical sea surface temperature analysis to help travelers find the perfect swimming window. Built with a modular **Infrastructure as Code (IaC)** approach using Terraform.

## Architecture Overview

The project follows a standard **Three-Tier Architecture** integrated with AWS Serverless components:

- **Frontend/Web Tier**: A lightweight, responsive frontend hosted on **Amazon EC2** (Amazon Linux 2023) using the Apache Web Server within a public subnet.
- **Logic Tier**: **AWS Lambda** (Python 3.11) triggered by **Amazon API Gateway (HTTP API)**.
- **Data Tier**: **Amazon DynamoDB** for search history persistence.
- **Monitoring/Security Tier**: CloudWatch (Observability), SNS (Alerting), CloudTrail (Auditing), and SSM Parameter Store (Secrets Management).



## 🛠️ Key Features & Technical Highlights

### 1. Serverless Analysis Engine
- **Satellite Data Integration**: Lambda fetches geographical coordinates and 365 days of marine data of a city via the Open-Meteo API.
- **Logic**: Analyzes daily max/min temperatures to identify "Comfortable Swimming Windows" (Avg Temp ≥ 21°C).
- **Data Visualization**: Returns a time-series dataset rendered on the frontend using **Chart.js**.

### 2. Infrastructure as Code (Modular Terraform)
- The environment is fully automated and modularized into:
  - `network.tf`: VPC, Subnets, Internet Gateway, and Routing.
  - `compute.tf`: EC2 Instance with automated `userdata` injection.
  - `serverless.tf`: Lambda, DynamoDB, and API Gateway configurations.
  - `monitoring.tf`: Observability and Auditing stack.

### 3. Observability & Professional Monitoring
- **Real-time Dashboard**: A custom **CloudWatch Dashboard** tracks Lambda invocations/errors, EC2 CPU load, and DynamoDB throughput.
- **Proactive Alerting**: Configured **CloudWatch Alarms** that trigger **SNS email notifications** upon system failures.
- **Security Auditing**: **AWS CloudTrail** logs all API activities to an S3 bucket for compliance and traceability.

### 4. Security Best Practices
- **Secrets Management**: Sensitive data (e.g., alert emails) is stored in **AWS SSM Parameter Store** and fetched dynamically, ensuring no PII (Personally Identifiable Information) is leaked in the source code.
- **IAM Least Privilege**: Fine-grained IAM policies for Lambda to access only necessary DynamoDB and CloudWatch resources.

## 🚀 How to Deploy

1. **Manual Setup**: Create a parameter in AWS SSM Parameter Store at `/seaside/sns_email` with your alert email address.
2. **Initialize**: `terraform init`
3. **Plan**: `terraform plan`
4. **Deploy**: `terraform apply -auto-approve`
5. **Access**: Open the Public IP of your EC2 instance and navigate to `/seaside.html`.

## 📈 Monitoring Demo

To verify the monitoring stack:
1. Trigger a manual error in the Lambda function.
2. Observe the **CloudWatch Alarm** state change.
3. Check your inbox for the **SNS Alert**.
4. View the audit trail in **CloudTrail** to see the "Invoke" event details.
