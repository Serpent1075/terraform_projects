resource "aws_iam_role" "aws_batch_service_role" {
  name = "BatchServiceRole"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
        "Service": [
          "batch.amazonaws.com",
          "ecs-tasks.amazonaws.com"
        ]
        }
    }
    ]
}
EOF
}

locals {
  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole",
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role_attach" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = element(local.role_policy_arns, count.index)
}

resource "aws_iam_role_policy" "aws_batch_service_policy" {
  name = "BatchServicePolicy"
  role = aws_iam_role.aws_batch_service_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
            "secretsmanager:GetSecretValue",
            "kms:Decrypt"
        ],
        "Resource": [
            "*",
        ]
      }
    ]
  })
}

