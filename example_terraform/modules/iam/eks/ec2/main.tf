locals {
  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_instance_profile" "this" {
  name = "EKS-Node-Profile-${var.prefix}"
  role = aws_iam_role.kuber_ec2_role.name
}


resource "aws_iam_role_policy_attachment" "this" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.kuber_ec2_role.name
  policy_arn = element(local.role_policy_arns, count.index)
}

resource "aws_iam_role" "kuber_ec2_role" {
  name = "${var.prefix}-kuber-ec2-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}
