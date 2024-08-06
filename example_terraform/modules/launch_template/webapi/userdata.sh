sudo yum -y update
sudo amazon-linux-extras install collectd -y
sudo systemctl enable collectd.service
sudo systemctl start collectd.service
sudo yum install amazon-cloudwatch-agent -y
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-newWebServer
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a start
sudo yum install -y amazon-efs-utils
sudo systemctl enable amazon-efs-utils
sudo systemctl start amazon-efs-utils
mkdir /config
sudo mount -t efs -o tls fs-abcd123456789ef0:/ /config