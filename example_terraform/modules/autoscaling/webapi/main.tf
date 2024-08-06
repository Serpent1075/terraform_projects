#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
resource "aws_autoscaling_group" "webapi_asg" {
  name = "${var.prefix}-asg"
  desired_capacity   = 0
  max_size           = 2
  min_size           = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = var.zone_id

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }
  

  lifecycle {
    create_before_destroy = false
    ignore_changes = [target_group_arns]
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix}-asg"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.webapi_asg.id
  lb_target_group_arn    = var.alb_targetgroup_arn
}