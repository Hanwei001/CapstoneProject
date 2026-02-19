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








# #Create S3 bucket
# resource "aws_s3_bucket" "myS3bucket" {
#   bucket = "mys3bucket-seaside-vacation-adviser-4622096"
# }


