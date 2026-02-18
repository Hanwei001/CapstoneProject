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