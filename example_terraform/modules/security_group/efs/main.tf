resource "aws_security_group" "efs_sg" {
  name        = "${var.prefix}-efs-sg"
  description = "Allow NFS inbound traffic"
  vpc_id = var.vpc_id

  tags = {
    Name = "NFS Security Group"
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.efs_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_nfs_inbound_from_webapi_sg" {
  type              = "ingress"
  from_port         = var.nfsport
  to_port           = var.nfsport
  protocol          = "tcp"
  security_group_id = aws_security_group.efs_sg.id
  source_security_group_id = var.webapi-sg
}

resource "aws_security_group_rule" "allow_nfs_inbound_from_batch_sg" {
  type              = "ingress"
  from_port         = var.nfsport
  to_port           = var.nfsport
  protocol          = "tcp"
  security_group_id = aws_security_group.efs_sg.id
  source_security_group_id = var.batch-sg
}

