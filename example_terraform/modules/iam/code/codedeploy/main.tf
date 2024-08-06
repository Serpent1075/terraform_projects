resource "aws_iam_role" "this" {
  name = "CodeDeploy-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy" "autoscaling_codedeploy" {
  name = "CodeDeploy-Policy"
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
        }
    ]
  })
}