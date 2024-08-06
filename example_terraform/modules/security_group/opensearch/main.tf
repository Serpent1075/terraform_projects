resource "aws_security_group" "opensearch" {
  name        = "${var.prefix}-opensearch-sg"
  description = "Managed by ${var.prefix}-Terraform"
  vpc_id      = var.vpc_id

 tags = {
    Name = "${var.prefix}-OpenSearch Security Group"
    사용자 = "${var.user_tag}"
  }

}


resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.opensearch.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_https_inbound_to_opensearch" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.opensearch.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_http_inbound_to_opensearch" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.opensearch.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_https_inbound_self" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.opensearch.id
  self = true  
}