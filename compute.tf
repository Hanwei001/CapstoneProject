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