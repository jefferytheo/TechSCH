# VPC configuration
resource "aws_vpc" "capstone_vpc_main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "tf_capstone_vpc_main"
  }
}

# Subnet configuration
resource "aws_subnet" "capstone_sb_main" {
  vpc_id     = aws_vpc.capstone_vpc_main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Capstone Main"
  }
}

resource "aws_subnet" "capstone_sb_secondary" {
  vpc_id     = aws_vpc.capstone_vpc_main.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"

  tags = {
    Name = "Capstone Secondary"
  }
}

# Internet gateway
resource "aws_internet_gateway" "capstone_gw" {
  vpc_id = aws_vpc.capstone_vpc_main.id

  tags = {
    Name = "Capstone main"
  }
}

# Route table & association
resource "aws_route_table" "capstone_rtb_main" {
  vpc_id = aws_vpc.capstone_vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.capstone_gw.id
  }


  tags = {
    Name = "Route table main"
  }
}

resource "aws_route_table" "capstone_rtb_secondary" {
  vpc_id = aws_vpc.capstone_vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.capstone_gw.id
  }


  tags = {
    Name = "Route table secondary"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.capstone_sb_main.id
  route_table_id = aws_route_table.capstone_rtb_main.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.capstone_sb_secondary.id
  route_table_id = aws_route_table.capstone_rtb_secondary.id
}


# resource "aws_route_table_association" "b" {
#   gateway_id     = aws_internet_gateway.capstone_gw.id
#   route_table_id = aws_route_table.capstone_rtb_secondary.id
# }

# Security group
resource "aws_security_group" "capstone_allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.capstone_vpc_main.id

  tags = {
    Name = "capstone_allow_http"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.capstone_vpc_main.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "capstone_allow_http_ipv4" {
  security_group_id = aws_security_group.capstone_allow_http.id
  cidr_ipv4         = aws_vpc.capstone_vpc_main.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = aws_vpc.capstone_vpc_main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# resource "aws_vpc_security_group_ingress_rule" "capstone_allow_http_ipv6" {
#   security_group_id = aws_security_group.capstone_allow_http.id
#   cidr_ipv6         = aws_vpc.capstone_vpc_main.ipv6_cidr_block
#   from_port         = 80
#   ip_protocol       = "tcp"
#   to_port           = 80
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv6         = aws_vpc.capstone_vpc_main.ipv6_cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.capstone_allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.capstone_allow_http.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_key_pair" "deployer" {
  key_name   = "capstone-key"
  public_key = file("~/.ssh/capstone_key.pub")
}