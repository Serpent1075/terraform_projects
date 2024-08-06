

resource "aws_security_group" "kuber_sg" {
  name        = "${var.prefix}-kuber-cluster-sg"
  description = "Allow Traffic to Ednpoint"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.prefix}-kuber-cluster-sg"
    //"aws:eks:cluster-name" =  "${var.cluster_name}"
    //"kubernetes.io/cluster/${var.cluster_name}"	= owned
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.kuber_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_tcp_inbound_from_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.kuber_sg.id
  self = true
}


resource "aws_security_group_rule" "allow_https_inbound_from_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.kuber_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}


resource "aws_security_group_rule" "allow_https_inbound_from_control_plane" {
  type              = "ingress"
  from_port         = 9443
  to_port           = 9443
  protocol          = "tcp"
  security_group_id = aws_security_group.kuber_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_https_inbound_from_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.kuber_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_https_inbound_from_dnsudp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.kuber_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_https_inbound_from_dnstcp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  security_group_id = aws_security_group.kuber_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_https_inbound_from_coredns" {
  type              = "ingress"
  from_port         = 9153
  to_port           = 9153
  protocol          = "tcp"
  security_group_id = aws_security_group.kuber_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_https_inbound_from_web" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.kuber_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_tcp_inbound_from_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.kuber_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
/*


*/