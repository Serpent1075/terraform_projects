data "aws_s3_bucket" "ext_nlb_acclog" {
  bucket = "prd-bcl-ext-nlb-ctech"
}


resource "aws_lb" "webapi_alb" {
  name               = "${var.prefix}-EN-${var.sufix}"
  internal           = false
  load_balancer_type = "network"
  security_groups    = var.sg
  subnets            = var.subnets_ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  idle_timeout = 600

  access_logs {
    bucket  = data.aws_s3_bucket.ext_nlb_acclog.bucket
    prefix  = "${var.prefix}-EN-${var.sufix}"
    enabled = true
  }

  tags = {
    Type = "External"
    Environment = "Production"
    Usage = "NLB"
    Suffix = "CTech"
    LBPos = "Main"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_lb_target_group" "https_front_end" {
  name        = "${var.prefix}-EN-${var.sufix}-${var.https_app_port}"
  port        = var.https_app_port
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
    PortType = "Main"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_lb_target_group" "http_front_end" {
  name        = "${var.prefix}-EN-${var.sufix}-${var.http_app_port}"
  port        = var.http_app_port
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
    PortType = "Main"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}


resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = aws_lb.webapi_alb.arn
  port              = "${var.listener_port}"
  protocol          = "TLS"

  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_arn
  alpn_policy       = "HTTP2Optional"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https_front_end.arn
  }
}

resource "aws_lb_listener" "front_end_http_redirect" {
  load_balancer_arn = aws_lb.webapi_alb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_front_end.arn
  }
}

data "aws_instances" "pa" {
  instance_tags = {
    Usage = "IPS"
    Type = "Production"
  }
}

resource "aws_lb_target_group_attachment" "pa_attach_http" {
  # covert a list of instance objects to a map with instance ID as the key, and an instance
  # object as the value.
  count = length(data.aws_instances.pa)

  target_group_arn = aws_lb_target_group.http_front_end.arn
  target_id        = element(data.aws_instances.pa.ids, count.index)
  port             = var.http_app_port
}

resource "aws_lb_target_group_attachment" "pa_attach_https" {
  # covert a list of instance objects to a map with instance ID as the key, and an instance
  # object as the value.
  count = length(data.aws_instances.pa)

  target_group_arn = aws_lb_target_group.https_front_end.arn
  target_id        = element(data.aws_instances.pa.ids, count.index)
  port             = var.https_app_port
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