resource "aws_launch_template" "webapi_lt" {
  name = "${var.prefix}-standalone-launchtemplate"

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
    associate_public_ip_address = true
    security_groups = [var.sg-id]
    subnet_id = var.webapi-subnet-id
  }


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.prefix}-standalone"
    }
  }

  user_data = "${base64encode(data.template_file.userdata.rendered)}"
}

data "template_file" "userdata" {
  template = <<EOF
#!bin/bash
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
wget -O- https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /usr/share/keyrings/postgresql.gpg
echo deb [arch=amd64,arm64,ppc64el signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main | sudo tee /etc/apt/sources.list.d/postgresql.list
apt-get -y update

apt install net-tools -y
apt-get install -y nginx
apt install -y redis-server
apt install postgresql-client postgresql -y
systemctl enable postgresql --now
apt-get install -y mongodb-org
systemctl start mongod
apt install -y collectd
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:${var.ps-cw-config}
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a start
sudo apt-get install letsencrypt -y
EOF
}
