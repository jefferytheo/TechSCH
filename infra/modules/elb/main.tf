# Load Balancer
resource "aws_lb" "capstone_elb" {
  name               = "capstone-elb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.prj_capstone_sg_id]
  subnets            = [var.prj_capstone_sub_id, var.prj_capstone_sub_secondary_id]

  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "capstone_production"
  }
}

# Target groups
resource "aws_lb_target_group" "capstone_tg" {
  name     = "tf-capstone-lb-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = var.prj_capstone_vpc_id  #aws_vpc.capstone_vpc_main.id
}

# Loadbalancer Listener
resource "aws_lb_listener" "capstone_front_end" {
  load_balancer_arn = aws_lb.capstone_elb.arn
  port              = "80"
  protocol          = "HTTP"
  # ssl_policy        = "ELBSecurityPolicy-2016-08"
  # certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.capstone_tg.arn
  }
}
