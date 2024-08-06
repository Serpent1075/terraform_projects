resource "aws_security_group" "msk_sg" {
  name        = "${var.prefix}-msk"
  description = "Allow TLS inbound traffic"
  vpc_id = var.vpc_id

  tags = {
    Name = "Webapi Security Group"
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.msk_sg.id
  cidr_blocks       = var.source_cidr_blocks_for_all_outbound_ipv4
  ipv6_cidr_blocks = var.source_cidr_blocks_for_all_outbound_ipv6
}

resource "aws_security_group_rule" "allow_http_inbound_from_cidr_blocks" {
  type              = "ingress"
  from_port         = var.msk_port
  to_port           = var.msk_port
  protocol          = "tcp"
  security_group_id = aws_security_group.msk_sg.id
  cidr_blocks       = var.source_cidr_blocks_for_msk_ipv4
  ipv6_cidr_blocks = var.source_cidr_blocks_for_msk_ipv6
}
