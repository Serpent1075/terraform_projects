data "aws_instances" "pa" {
  instance_tags = {
    Usage = "IPS"
    Type = "Production"
  }
}

resource "aws_lb_target_group" "custom" {
  name        = "${var.prefix}-EN-${var.sufix}-1${var.app_port}"
  port        = var.app_port + 10000
  protocol    = "TCP"
  vpc_id      = var.vpc_id


  health_check {
    port     = 222
    protocol = "HTTPS"
    matcher = "200-399"
    path = "/"
  }

  /*
  health_check {
    port     = 8443
    protocol = "HTTP"
    matcher = "200-399"
    path = "/health.pa"
  }
  */

  tags = {
    Type = "External"
    Environment = "Production"
    Usage = "NLB"
    Suffix = "CTech"
    PortType = "Custom"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}


resource "aws_lb_listener" "custom" {
  load_balancer_arn = var.alb_arn
  port              = "${var.app_port}"
  protocol          = "TLS"
  
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_arn
  alpn_policy       = "HTTP2Optional"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.custom.arn
    
  }
}

resource "aws_lb_target_group_attachment" "custom" {
  # covert a list of instance objects to a map with instance ID as the key, and an instance
  # object as the value.
  count = length(data.aws_instances.pa)

  target_group_arn = aws_lb_target_group.custom.arn
  target_id        = element(data.aws_instances.pa.ids, count.index)
  port             = var.app_port + 10000
}
