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