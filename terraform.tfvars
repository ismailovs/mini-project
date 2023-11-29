security_groups = {
  "app_sg" : {
    description = "Security group for web servers"
    ingress_rules = [
      {
        description = "ingress rule for http"
        priority    = 200
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      },
      {
        description = "my_ssh"
        priority    = 202
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      },
      {
        description = "ingress rule for https"
        priority    = 204
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
    egress_rules = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }
}

subnets = {
  Dev-subnet = {
    cidr_block        = "10.0.1.0/24"
    availability_zone = "us-east-1a"
  }
  Web-subnet = {
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-east-1b"
  }
  App-subnet = {
    cidr_block        = "10.0.3.0/24"
    availability_zone = "us-east-1c"
  }
}

ec2 = {
  Dev-server = {
    server_name = "1"
    subnet = "Dev-subnet"
  }
  Web-server = {
    server_name = "2"
    subnet = "Web-subnet"
  }
  App-server = {
    server_name = "3"
    subnet = "App-subnet"
  }
}