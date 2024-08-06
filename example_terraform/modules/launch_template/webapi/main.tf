

resource "aws_launch_template" "webapi_lt" {
  name = "${var.prefix}-launchtemplate"

  disable_api_termination = false

  ebs_optimized = true

  iam_instance_profile {
    name = var.iam-name
  }

  image_id = var.image_id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.instance_type

  key_name = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [var.sg-id]
    subnet_id = var.webapi-subnet-id
  }


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.prefix}-webapi"
    }
  }

  user_data = "${base64encode(data.template_file.userdata.rendered)}"
}

data "template_file" "userdata" {
  template = <<EOF
#!bin/bash
sudo yum -y update
sudo amazon-linux-extras install collectd -y
sudo systemctl enable collectd.service
sudo systemctl start collectd.service
sudo yum install amazon-cloudwatch-agent -y
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:${var.ps-cw-config}
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a start
sudo yum install -y amazon-efs-utils
sudo systemctl enable amazon-efs-utils
sudo systemctl start amazon-efs-utils
mkdir /config
sudo mount -t efs -o tls ${var.file-system-id}:/ /config
sudo chmod go+rw /config
sudo yum -y install ruby
wget https://aws-codedeploy-${var.aws_region}.s3.${var.aws_region}.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent start
EOF
}

