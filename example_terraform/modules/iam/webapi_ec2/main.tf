locals {
  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
  ]
}

resource "aws_iam_instance_profile" "this" {
  name = "EC2-Profile-${var.prefix}"
  role = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = element(local.role_policy_arns, count.index)
}
/*
resource "aws_iam_role_policy_attachment" "args" {
  count = length(var.role_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = element(var.role_policy_arns, count.index)
}
*/

resource "aws_iam_role_policy" "autoscaling_codedeploys3" {
  name = "AutoScalingForCodeDeployANDS3-${var.prefix}"
  role = aws_iam_role.this.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EC2InstanceManagement",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:RunInstances"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EC2InstanceProfileManagement",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": "ec2.amazonaws.com*"
                }
            }
        },
        {
            "Sid": "EC2InstanceS3Management",
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

resource "aws_iam_role" "this" {
  name = "EC2-Role-${var.prefix}"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          },
          "Effect" : "Allow"
        }
      ]
    }
  )
}