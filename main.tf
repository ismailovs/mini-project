resource "aws_key_pair" "key" {
  key_name   = "${var.prefix}-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.prefix}-vpc"
  }
}
resource "aws_subnet" "subnet" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags = {
    Name = join("-", [var.prefix, each.key])
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.prefix}-igw"
  }
}
resource "aws_eip" "eip" {
  for_each = var.ec2
  instance = aws_instance.server[each.key].id
  domain   = "vpc"
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.prefix}-public-rt"
  }
}
resource "aws_route_table_association" "rta" {
  for_each = var.subnets
  subnet_id      = aws_subnet.subnet[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}
module "security_groups" {
  source  = "app.terraform.io/s_tc_1/security_groups/aws"
  version = "1.0.0"
  vpc_id          = aws_vpc.main.id
  security_groups = var.security_groups
}
 
resource "aws_instance" "server" {
  for_each = var.ec2
  ami           = "ami-0230bd60aa48260c6"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key.key_name
  subnet_id              = aws_subnet.subnet[each.value.subnet].id
  vpc_security_group_ids = [module.security_groups.security_group_id["app_sg"]]
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd.service
              sudo systemctl enable httpd.service
              sudo echo "<h1> Hello World from ${each.value.server_name}</h1>" > /var/www/html/index.html                   
              EOF
  tags = {
    Name = join("-", [var.prefix, each.key])
  }
}

output "security_group_id" {
  value = { for k, v in aws_eip.eip : k => v.public_ip }
}