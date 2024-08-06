resource "aws_security_group" "loadbalancer_sg" {
  name        = "${var.prefix}-loadbalancer-sg"
  description = "Allow TLS inbound traffic"
  vpc_id = var.vpc_id

  tags = {
    Name = "Load Balancer Security Group"
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.loadbalancer_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_http_inbound_from_cidr_blocks" {
  type              = "ingress"
  from_port         = var.http
  to_port           = var.http
  protocol          = "tcp"
  security_group_id = aws_security_group.loadbalancer_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_https_inbound_from_cidr_blocks" {
  type              = "ingress"
  from_port         = var.https
  to_port           = var.https
  protocol          = "tcp"
  security_group_id = aws_security_group.loadbalancer_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}