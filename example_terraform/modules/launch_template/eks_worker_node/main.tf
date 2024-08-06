

resource "aws_launch_template" "eks_worker_node_lt" {
  name = "${var.prefix}-eks-launchtemplate"

  vpc_security_group_ids = var.sg-ids

  ebs_optimized = true

  image_id = var.image_id
  
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp3"
    }
  }
/*
  instance_market_options {
    market_type = "spot"
    spot_options  {
      block_duration_minutes = 180
      max_price =  0.043
      spot_instance_type = "persistent"
      instance_interruption_behavior = "terminate"
    }
  }
*/

  instance_type = var.instance_type

  key_name = var.key_name

/*
  network_interfaces {
    associate_public_ip_address = false
    //security_groups = var.sg-id
  }
*/

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.prefix}-eks-node"
      //"kubernetes.io/cluster/${var.cluster_name}" = "owned"
      //"k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      //"k8s.io/cluster-autoscaler/${var.cluster_name}" = "true"
      //"eks:cluster-name" = "${var.cluster_name}"
    }
  }

  user_data = "${base64encode(data.template_file.userdata.rendered)}"
}

data "template_file" "userdata" {
  template = <<EOF
#!/bin/bash
/etc/eks/bootstrap.sh jhoh-tf-ec2-kuber
EOF
}
