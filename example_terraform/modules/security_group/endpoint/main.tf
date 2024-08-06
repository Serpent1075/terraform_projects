resource "aws_security_group" "endpoint_sg" {
  name        = "${var.prefix}-endpoint-sg"
  description = "Allow Traffic to Ednpoint"
  vpc_id = var.vpc_id

  tags = {
    Name = "Enpoint Security Group"
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.endpoint_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}


resource "aws_security_group_rule" "allow_https_inbound_from_all" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.endpoint_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
