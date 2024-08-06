resource "aws_codedeploy_app" "codedeploy_app" {
  name             = "${var.prefix}-codedeploy-app"
}

resource "aws_codedeploy_deployment_config" "codedeploy_config" {
  deployment_config_name = "${var.prefix}-deployment-config"

  minimum_healthy_hosts {
    type  = "HOST_COUNT"
    value = 1
  }

}

resource "aws_sns_topic" "codedeploy_sns_topic" {
  name = "${var.prefix}-codedeploy-topic"
}

resource "aws_codedeploy_deployment_group" "codedeploy_deployment_group" {
  app_name              = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name = "${var.prefix}-codedeploy-group"
  service_role_arn      = var.iam_arn
  deployment_config_name = aws_codedeploy_deployment_config.codedeploy_config.id
  autoscaling_groups = var.asg_name
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL" #WITHOUT_TRAFFIC_CONTROL
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    target_group_info {
      name = var.tg_name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_STOP_ON_ALARM"]
  }


  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 60
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }
}