resource "aws_lb" "webapi_ecs_alb" {
  name               = "${var.prefix}-ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.sg
  subnets            = var.subnets_ids

  enable_deletion_protection = false
/*
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-lb"
    enabled = true
  }
*/
  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "front_end" {
  name        = "${var.prefix}-ecs-alb-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id


  health_check {
    port     = var.app_port
    protocol = "HTTP"
    matcher = "200-399"
    path = "/ping"
  }
}


resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = aws_lb.webapi_ecs_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  certificate_arn   = var.acm_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

resource "aws_lb_listener" "front_end_http_redirect" {
  load_balancer_arn = aws_lb.webapi_ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}