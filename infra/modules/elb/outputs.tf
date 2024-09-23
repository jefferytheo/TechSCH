output "capstone_alb_tg_arn" {
  description = "ARN of ALB Target Group"
  value = aws_lb_target_group.capstone_tg.arn
}