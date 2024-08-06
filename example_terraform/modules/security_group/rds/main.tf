resource "aws_security_group" "rds_sg" {
  name        = "${var.prefix}-rds-sg"
  description = "Allow TLS inbound traffic"
  vpc_id = var.vpc_id

  tags = {
    Name = "RDS Security Group"
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}


resource "aws_security_group_rule" "allow_postgresql_inbound_from_webapisg" {
  type              = "ingress"
  from_port         = var.psqlport
  to_port           = var.psqlport
  protocol          = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  source_security_group_id = var.webapi_sg_id
}

resource "aws_security_group_rule" "allow_postgresql_inbound_from_batchsg" {
  type              = "ingress"
  from_port         = var.psqlport
  to_port           = var.psqlport
  protocol          = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  source_security_group_id = var.batch_sg_id
}


resource "aws_security_group_rule" "allow_postgresql_inbound_from_lambdasg" {
  type              = "ingress"
  from_port         = var.psqlport
  to_port           = var.psqlport
  protocol          = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  source_security_group_id = var.lambda_sg_id
}
