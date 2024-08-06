data "aws_iam_role" "ecs_service_role" {
  name = "AWSServiceRoleForECS"
}


resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.prefix}-ecs-cluster"

  configuration {
    execute_command_configuration {
      kms_key_id = var.kms_arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = var.loggroup_name
      }
    }
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family = "${var.prefix}-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048 
  task_role_arn = var.iam_arn
  execution_role_arn       = "${var.task_execution_arn}"

  container_definitions = jsonencode([
    {
      name      = "${var.prefix}-webapi"
      image     = "${var.image_url}:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3010
          hostPort      = 3010
        }
      ]
      log_configuration = [
        {
          logDriver = "awslogs"
          options = [{
                    awslogs-create-group = true,
                    awslogs-group = "${var.loggroup_name}",
                    awslogs-region = "${var.aws_region}",
                    awslogs-stream-prefix = "ecs"
                }]
        }
      ]
    },
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64" //  ARM64  X86_64
  }

  volume {
    name = "service-storage"

    efs_volume_configuration {
      file_system_id          = var.file_system_id
      root_directory          = "/"
    }
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.prefix}-${var.imagename}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  launch_type = "FARGATE"
  desired_count   = 1
  
  network_configuration {
    subnets = var.subnets_ids
    security_groups = var.sg
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.lb_tg_arn
    container_name   = "${var.prefix}-webapi"
    container_port   = 3010
  }

}
