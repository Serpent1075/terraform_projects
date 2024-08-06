locals {
  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_instance_profile" "ecs_profile" {
  name = "ECS-Profile-${var.prefix}"
  role = aws_iam_role.ecs_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_policy_attachment" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.ecs_role.name
  policy_arn = element(local.role_policy_arns, count.index)
}
/*
resource "aws_iam_role_policy_attachment" "args" {
  count = length(var.role_policy_arns)

  role       = aws_iam_role.ecs_role.name
  policy_arn = element(var.role_policy_arns, count.index)
}
*/

resource "aws_iam_role_policy" "autoscaling_s3" {
  name = "AutoScalingANDS3-${var.prefix}"
  role = aws_iam_role.ecs_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ECSInstanceManagement",
            "Effect": "Allow",
            "Action": [
                "application-autoscaling:*",
                "ecs:DescribeServices",
                "ecs:UpdateService",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarmHistory",
                "cloudwatch:DescribeAlarmsForMetric",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "cloudwatch:DisableAlarmActions",
                "cloudwatch:EnableAlarmActions",
                "iam:CreateServiceLinkedRole",
                "sns:CreateTopic",
                "sns:Subscribe",
                "sns:Get*",
                "sns:List*",
            ],
            "Resource": "*"
        },
        {
            "Sid": "ECSS3Management",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            "Resource": "*",
        }
    ]
  })
}

resource "aws_iam_role" "ecs_role" {
  name = "ECS-Role-${var.prefix}"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "ecs-tasks.amazonaws.com"
          },
          "Effect" : "Allow"
        }
      ]
    }
  )
}