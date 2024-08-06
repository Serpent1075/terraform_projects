output "alb_id" {
  value = aws_lb.webapi_alb.id
  description = "Application LoadBalancer id"
}

output "alb_name" {
  value = aws_lb.webapi_alb.name
  description = "Application LoadBalancer name"
}

output "alb_dns_name" {
  value = aws_lb.webapi_alb.dns_name
  description = "Application LoadBalancer DNS name"
}
output "alb_arn" {
  value = aws_lb.webapi_alb.arn
  description = "Application LoadBalancer ARN"
}
/*
output "alb_target_group_arn" {
  value = aws_lb_target_group.front_end.arn
  description = "Application LoadBalancer Target Group ARN"
}

output "alb_target_group_name" {
  value = aws_lb_target_group.front_end.name
  description = "Application LoadBalancer Target Group name"
}

*/