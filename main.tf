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
              sudo echo "<h1> Helloo World from ${each.value.server_name}</h1>" > /var/www/html/index.html                   
              EOF
  tags = {
    Name = join("-", [var.prefix, each.key])
  }
}

# # IMPORTING aws_internet_gateway.gw
# import {  
#   to = aws_internet_gateway.gw
#   id = "igw-08334028f7e8384de"
#   }
# #IMPORTING aws_key_pair.key
# import {  
#   to = aws_key_pair.key
#   id = "mini-project-key"
#   }
# #IMPORTING aws_route_table.public_route_table 
# import {  
#   to = aws_route_table.public_route_table
#   id = "rtb-03eb89491b753b607"
#   }
# #IMPORTING aws_vpc.main
# import {  
#   to = aws_vpc.main
#   id = "vpc-04e538125210dfb6b"
#   }
# #IMPORTING module.security_groups.aws_security_group.default["app_sg"]
# import {  
#   to = module.security_groups.aws_security_group.default["app_sg"]
#   id = "sg-0081abd02ff43089b"
#   }

# #APP:
# import {  
#   to = aws_instance.server["App-server"]
#   id = "i-07e7df9cfdb9e30fc"
#   }
# #IMPORTING aws_eip.eip["App-server"]
# import {  
#   to = aws_eip.eip["App-server"]
#   id = "eipalloc-07a51879121fcc45a"
#   }
# #IMPORTING aws_route_table_association.rta["App-subnet"]
# import {  
#   to = aws_route_table_association.rta["App-subnet"]
#   id = "subnet-0c747f29cd29f5747/rtb-03eb89491b753b607"
#   }
# #IMPORTING aws_subnet.subnet["App-subnet"]
# import {  
#   to = aws_subnet.subnet["App-subnet"]
#   id = "subnet-0c747f29cd29f5747"
#   }

# #DEV:
# #IMPORTING aws_instance.server["Dev-server"] 
# import {  
#   to = aws_instance.server["Dev-server"]
#   id = "i-077cfb6d6b1910cc5"
#   }
# #IMPORTING aws_eip.eip["Dev-server"]
# import {  
#   to = aws_eip.eip["Dev-server"]
#   id = "eipalloc-0546313fa087f36f1"
#   }
# #IMPORTING aws_route_table_association.rta["Dev-subnet"]
# import {  
#   to = aws_route_table_association.rta["Dev-subnet"]
#   id = "subnet-0c8730697690c9987/rtb-03eb89491b753b607"
#   }
# #IMPORTING aws_subnet.subnet["Dev-subnet"] 
# import {  
#   to = aws_subnet.subnet["Dev-subnet"] 
#   id = "subnet-0c8730697690c9987"
#   }


# #WEB:
# #IMPORTING aws_instance.server["Web-server"]
# import {  
#   to = aws_instance.server["Web-server"] 
#   id = "i-08d352d1282f91786"
#   }
# #IMPORTING aws_eip.eip["Web-server"] 
# import {  
#   to = aws_eip.eip["Web-server"] 
#   id = "eipalloc-0b854bb1688f2db44"
#   }
# #IMPORTING aws_route_table_association.rta["Web-subnet"]
# import {  
#   to = aws_route_table_association.rta["Web-subnet"]
#   id = "subnet-0044cd6c7c436b861/rtb-03eb89491b753b607"
#   }
# #IMPORTING aws_subnet.subnet["Web-subnet"] 
# import {  
#   to = aws_subnet.subnet["Web-subnet"] 
#   id = "subnet-0044cd6c7c436b861"
#   }


output "security_group_id" {
  value = { for k, v in aws_eip.eip : k => v.public_ip }
}