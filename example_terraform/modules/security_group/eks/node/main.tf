resource "aws_security_group" "kuber_sg" {
  name        = "${var.prefix}-kuber-node-sg"
  description = "Allow Traffic to Ednpoint"
  vpc_id = var.vpc_id

  tags = {
    Name = "Kubernetes Security Group"
    //"aws:ec2launchtemplate:id" = var.launch_template_id
    //"eks:nodegroup-name" = var.node_group_name
    //"eks:cluster-name"	= var.cluster_name
    //"aws:eks:cluster-name" = var.cluster_name
    //"aws:ec2launchtemplate:version" = var.launch_template_version
    //"kubernetes.io/cluster/${var.cluster_name}" = owned
    //aws:autoscaling:groupName = var.autoscaling_group_name
    //k8s.io/cluster-autoscaler/enabled	true
    //k8s.io/cluster-autoscaler/${var.cluster_name} = owned
  }
}

resource "aws_security_group_rule" "allow_all_inbound_from_cluster" {
  type              = "ingress"
  from_port         = 0
  to_port           = 9443
  protocol          = "tcp"
  security_group_id = aws_security_group.kuber_sg.id
  source_security_group_id = var.cluster_sg_id
}

resource "aws_security_group_rule" "allow_all_tcp_inbound_from_alb" {
  type              = "ingress"
  from_port         = 0
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.kuber_sg.id
  source_security_group_id = var.alb_sg_id
}
/*
resource "aws_security_group_rule" "allow_tcp_inbound_from_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.kuber_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

*/



resource "aws_security_group_rule" "allow_traffic_inbound_from_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.kuber_sg.id
  self = true
}
