output "alb-id" {
  value = aws_lb.webapi_alb.id
  description = "Application LoadBalancer id"
}

output "alb-name" {
  value = aws_lb.webapi_alb.name
  description = "Application LoadBalancer name"
}
output "alb-arn" {
  value = aws_lb.webapi_alb.arn
  description = "Application LoadBalancer ARN"
}
output "alb-target-group-arn" {
  value = aws_lb_target_group.front_end.arn
  description = "Application LoadBalancer Target Group ARN"
}

output "alb-target-group-name" {
  value = aws_lb_target_group.front_end.name
  description = "Application LoadBalancer Target Group name"
}

