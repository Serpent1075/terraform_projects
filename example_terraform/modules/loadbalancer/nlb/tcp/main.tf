data "aws_s3_bucket" "int_nlb_acclog" {
  bucket = "prd-thinkbig-int-nlb-ctech"
}

resource "aws_lb" "webapi_alb" {
  name               = "${var.prefix}-IN-${var.sufix}"
  internal           = true
  load_balancer_type = "network"
  security_groups    = var.sg
  subnets            = var.subnets_ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  idle_timeout = 600

  access_logs {
    bucket  = data.aws_s3_bucket.int_nlb_acclog.bucket
    prefix  = "${var.prefix}-IN-${var.sufix}"
    enabled = true
  }

  tags = {
    Type = "Internal"
    Environment = "Production"
    Usage = "NLB"
    Suffix = "CTech"
    LBPos = "Main"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_lb_target_group" "front_https_end" {
  name        = "${var.prefix}-IN-${var.sufix}-8443"
  port        = 8443
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


resource "aws_lb_target_group" "front_http_end" {
  name        = "${var.prefix}-TG-${var.sufix}-80"
  port        = 80
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
    PortType = "Main"
  }
  
  lifecycle {
    ignore_changes = [tags]
  }
}



resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = aws_lb.webapi_alb.arn
  port              = var.listener_https_port
  protocol          = "TCP"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_https_end.arn
  }
}




resource "aws_lb_listener" "front_end_http" {
  load_balancer_arn = aws_lb.webapi_alb.arn
  port              = var.listener_http_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_http_end.arn
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
  port             = var.https_app_port
}

resource "aws_lb_target_group_attachment" "waf_attach_http" {
  # covert a list of instance objects to a map with instance ID as the key, and an instance
  # object as the value.
  count = length(data.aws_instances.waf)

  target_group_arn = aws_lb_target_group.front_http_end.arn
  target_id        = element(data.aws_instances.waf.ids, count.index)
  port             = var.http_app_port
}



/*
resource "aws_lb_target_group_attachment" "pa_attach_http" {
  # covert a list of instance objects to a map with instance ID as the key, and an instance
  # object as the value.
  count = length(data.aws_instances.pa)

  target_group_arn = aws_lb_target_group.http_front_end.arn
  target_id        = element(data.aws_instances.pa.ids, count.index)
  port             = var.http_app_port
}

*/