resource "aws_lb_target_group" "front_https_end" {
  name        = "${var.prefix}-IN-${var.sufix}-${var.app_port}"
  port        = var.app_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id

  health_check {
    port     = 5000
    protocol = "HTTP"
    matcher = "200-399"
    path = "/"
  }

  tags = {
    Type = "Internal"
    Environment = "Production"
    Usage = "NLB"
    Suffix = "CTech"
    PortType = "Main"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}



resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = var.nlb_arn
  port              = var.app_port+10000
  protocol          = "TCP"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_https_end.arn
  }
}



data "aws_instances" "waf" {
  instance_tags = {
    Usage = "WAF"
    Type = "Production"
  }
}

resource "aws_lb_target_group_attachment" "waf_attach_https" {
  # covert a list of instance objects to a map with instance ID as the key, and an instance
  # object as the value.
  count = length(data.aws_instances.waf)

  target_group_arn = aws_lb_target_group.front_https_end.arn
  target_id        = element(data.aws_instances.waf.ids, count.index)
  port             = var.app_port
}