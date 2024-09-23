provider "aws" {
  region = "us-east-1"
}


#VPC
resource "aws_vpc" "tf_vpc_main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "tf_vpc_main"
  }
}


#Subnets
resource "aws_subnet" "tf_subnet_main" {
  vpc_id                  = aws_vpc.tf_vpc_main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf_subnet_main"
  }
}

resource "aws_subnet" "tf_subnet_secondary" {
  vpc_id                  = aws_vpc.tf_vpc_main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf_subnet_secondary"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "tf_gw" {
  vpc_id = aws_vpc.tf_vpc_main.id

  tags = {
    Name = "tf_gw"
  }
}

# Routing Table
resource "aws_route_table" "tf_route_tb" {
  vpc_id = aws_vpc.tf_vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_gw.id
  }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  # }

  tags = {
    Name = "tf_route_tb"
  }
}

# Routing Table Assoc
resource "aws_route_table_association" "tf_rta" {
  subnet_id      = aws_subnet.tf_subnet_main.id
  route_table_id = aws_route_table.tf_route_tb.id
}


resource "aws_route_table_association" "tf_rtb" {
  subnet_id      = aws_subnet.tf_subnet_secondary.id
  route_table_id = aws_route_table.tf_route_tb.id
}


# Security Group
resource "aws_security_group" "tf_sg_main" {
  name        = "tf_sg_main"
  description = "Allow HTTP/HTTPS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.tf_vpc_main.id
  lifecycle {
    create_before_destroy = true
    # Reference the security group as a whole or individual attributes like `name`
    #replace_triggered_by = [aws_security_group.tf_sg_main]
  }
  tags = {
    Name = "tf_sg_main"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.tf_sg_main.id
  cidr_ipv4         = "0.0.0.0/0" #aws_vpc.tf_vpc_main.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.tf_sg_main.id
  cidr_ipv4         = "0.0.0.0/0" #aws_vpc.tf_vpc_main.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


# resource "aws_vpc_security_group_ingress_rule" "https" {
#   security_group_id = aws_security_group.tf_sg_main.id
#   cidr_ipv4         = aws_vpc.tf_vpc_main.cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.tf_sg_main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#VPC -  Security Group
# module "vpc" {
#   source = "./modules/vpc"
#   aws_cidr_blocks = var.aws_cidr_blocks
#   #aws_subnet_cidr_blocks = var.aws_subnet_cidr_blocks
#   aws_availability_zones = var.aws_availability_zones
# }

#ALB
resource "aws_lb" "tf_lb_test" {
  name               = "tf-lb-test"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf_sg_main.id]
  subnets            = [aws_subnet.tf_subnet_main.id, aws_subnet.tf_subnet_secondary.id]
  #subnets            = [for subnet in aws_subnet.tf_subnet_main : subnet.id]


  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "dev"
  }
}

#Target Group
resource "aws_lb_target_group" "tf_tg_main" {
  name        = "tf-tg-main"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.tf_vpc_main.id
}

# ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.tf_lb_test.arn
  port              = 80
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf_tg_main.arn
  }
}


data "aws_iam_user" "user" {
  user_name = "adeolu"
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "deployer" {
  key_name   = "capstone-ansible-key"
  public_key = file("/home/adeolu/.ssh/capstone_key.pub")
}

resource "aws_instance" "ansible_servers" {
  count                       = 3
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.tf_subnet_main.id
  key_name                    = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.tf_sg_main.id]

  tags = {
    Name = "${element(["dev", "prod", "staging"], count.index)}-instance"
  }
}