output "gwlb_arn" {
  value = aws_lb.test.arn
  description = "GW LoadBalancer arn"
}
