variable "aws_region" {
  description = "AWS region to deploy into"
  type = string
}

variable "ami_id" {
  description = "AMI ID to use for the EC2 instance"
  type = string
}
 
variable "instance_type" {
  description = "EC2 instance type"
  type = string
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type = string
}

variable "sns_email_parameter_path" {
  description = "The path of the SSM parameter storing the SNS email"
  type        = string
  default     = "/seaside/sns_email" 
}