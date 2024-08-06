resource "aws_security_group" "lambda-sg" {
  name        = "${var.prefix}-lambda-sg"
  description = "Allow Traffic to Ednpoint"
  vpc_id = var.vpc_id

  tags = {
    Name = "Lambda Security Group"
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.lambda-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}


resource "aws_security_group_rule" "allow_http_inbound_from_cidr_blocks" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_dns_inbound_from_cidr_blocks" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.lambda-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
