resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true 
  enable_dns_support = true

  tags       =  {
    name     = "deham33"
  }
}
resource "aws_subnet" "public-1" {
  vpc_id     = aws_vpc.dev_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "deham33"
  }
}
