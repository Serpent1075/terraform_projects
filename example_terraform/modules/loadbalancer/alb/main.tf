data "aws_s3_bucket" "ext_alb_acclog" {
  bucket = "prd-bcl-ext-alb-ctech"
}



resource "aws_lb" "webapi_alb" {
  name               = "${var.prefix}-EA-${var.sufix}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.sg
  subnets            = var.subnets_ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  idle_timeout = 600

  access_logs {
    bucket  = data.aws_s3_bucket.ext_alb_acclog.bucket
    prefix  = "${var.prefix}-EA-${var.sufix}"
    enabled = true
  }

  tags = {
    Type = "External"
    Environment = "production"
    Usage = "ALB"
    Suffix = "CTech"
    LBPos = "Main"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_lb_target_group" "front_end" {
  name        = "${var.prefix}-EA-${var.sufix}-${var.app_port}"
  port        = var.app_port
  protocol    = "HTTP"
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
    Usage = "ALB"
    Suffix = "CTech"
    PortType = "Main"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}


resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = aws_lb.webapi_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "404"
    }
  }

  
}

resource "aws_lb_listener" "front_end_http_redirect" {
  load_balancer_arn = aws_lb.webapi_alb.arn
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

data "aws_instances" "pa" {
  instance_tags = {
    Usage = "IPS"
    Type = "Production"
  }
}

resource "aws_lb_target_group_attachment" "pa_attach" {
  # covert a list of instance objects to a map with instance ID as the key, and an instance
  # object as the value.
  count = length(data.aws_instances.pa)

  target_group_arn = aws_lb_target_group.front_end.arn
  target_id        = element(data.aws_instances.pa.ids, count.index)
  port             = var.app_port
}

##################
data "aws_acm_certificate" "arpediabookcom" {
  domain      = "*.arpediabook.com"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

resource "aws_lb_listener_certificate" "arpediabookcom" {
  listener_arn    = aws_lb_listener.front_end_https.arn
  certificate_arn = data.aws_acm_certificate.arpediabookcom.arn
}

################


resource "aws_lb_listener_rule" "thinkbig" {
  listener_arn = aws_lb_listener.front_end_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }

  condition {
    host_header {
      values = ["*.wjthinkbig.com"]
    }
  }
}

resource "aws_lb_listener_rule" "arpedia" {
  listener_arn = aws_lb_listener.front_end_https.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }

  condition {
    host_header {
      values = ["*.arpediabook.com"]
    }
  }
}

