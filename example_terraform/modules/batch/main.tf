resource "aws_batch_compute_environment" "batch-compute" {
  compute_environment_name = "${var.prefix}-batch-compute"

  compute_resources {
    max_vcpus = 16

    security_group_ids = [
      var.compute_security_group_id
    ]

    subnets = var.subnet_ids

    type = "FARGATE_SPOT"
  }

  service_role = var.batch-iam-arn
  type         = "MANAGED"
  depends_on   = [var.batch-iam-arn]
}

resource "aws_batch_job_queue" "batch-job-queue" {
  name     = "${var.prefix}-batch-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.batch-compute.arn
  ]
}

resource "aws_batch_job_definition" "batch-job-definition" {
  name = "${var.prefix}-batch-job-definition"
  type = "container"
  platform_capabilities = [
    "FARGATE",
  ]

#https://docs.aws.amazon.com/batch/latest/APIReference/API_RegisterJobDefinition.html
#Platform 버전 1.3.0을 사용할 경우 EFS 연결을 할 수 없음
  container_properties = <<CONTAINER_PROPERTIES
{
    "jobDefinitionName": "${var.prefix}-batch-job-definition",
    "command": ["./${var.app_name}", "Ref::uuid"],
    "image": "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.prefix}-container-registry:latest",
    "jobRoleArn": "${var.batch-iam-arn}",
    "fargatePlatformConfiguration": {
      "platformVersion": "1.4.0"
    },
    "resourceRequirements": [
      {"type": "VCPU", "value": "${var.vcpu}"},
      {"type": "MEMORY", "value": "${var.mem}"}
    ],
    "executionRoleArn": "${var.batch-iam-arn}",
    "logConfiguration": { 
           "logDriver": "awslogs"
        },
    "mountPoints": [ 
           { 
              "containerPath": "/config",
              "readOnly": true,
              "sourceVolume": "${var.efsname}"
           }
        ],
    "volumes": [ 
           { 
              "efsVolumeConfiguration": { 
                 "fileSystemId": "${var.efs_file_system_id}",
                 "rootDirectory": "/"
              },
              "name": "${var.efsname}"
           }
        ],
    "secrets": [ 
           { 
              "name": "prefix",
              "valueFrom": "${var.sm_prefix_arn}"
           }, 
           { 
              "name": "redissecret",
              "valueFrom": "${var.sm_redis_arn}"
           },
           { 
              "name": "rdsssecret",
              "valueFrom": "${var.sm_rds_arn}"
           },
           { 
              "name": "pwsecret",
              "valueFrom": "${var.sm_pw_arn}"
           },
           { 
              "name": "mongosecret",
              "valueFrom": "${var.sm_mongo_arn}"
           }
        ]
  }
CONTAINER_PROPERTIES
}