resource "aws_lb" "test" {
  name               = "${var.prefix}-gwlb"
  internal           = false
  load_balancer_type = "gateway"
  subnets            = [for subnet in var.subnet_ids : subnet]

  enable_deletion_protection = false

  access_logs {
    bucket  = var.s3_id
    prefix  = "${var.prefix}-gwlb"
    enabled = true
  }

  tags = {
    Environment = "production"
    사용자 = "${var.user_tag}"
  }
}

resource "aws_lb_target_group" "test" {
  name     = "${var.prefix}-gw-lb-target"
  target_type = var.target_type
  port     = 6081
  protocol = var.protocol
  vpc_id   = var.vpc_id

  health_check {
    port     = 80
    protocol = "HTTP"
  }
}


resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.test.id

  default_action {
    target_group_arn = aws_lb_target_group.test.id
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = var.resource_ip
  port             = 80
}