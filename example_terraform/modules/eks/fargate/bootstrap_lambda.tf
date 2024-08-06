
#https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/deploy-coredns-on-amazon-eks-with-fargate-automatically-using-terraform-and-python.html
/*data "archive_file" "bootstrap_archive" {
  type        = "zip"
  source_dir  = "./modules/eks/fargate/python"
  output_path = "./modules/eks/fargate/main.zip"
}
 
resource "aws_security_group" "bootstrap" {
  name_prefix = var.cluster_name # Reference to EKS Cluster Name variable
  vpc_id      = var.vpc_id # Reference to VPC ID variable (VPC in which EKS Cluster is hosted)
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
resource "aws_iam_role" "bootstrap" {
  name_prefix        = var.cluster_name # Reference to EKS Cluster Name variable
  assume_role_policy = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON
}
 
resource "aws_iam_role_policy_attachment" "bootstrap" {
  role        = aws_iam_role.bootstrap.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
 
resource "aws_lambda_function" "bootstrap" {
  function_name    = "${var.cluster_name}-bootstrap"
  runtime          = "python3.7"
  handler          = "main.handler"
  role             = aws_iam_role.bootstrap.arn
  filename         = data.archive_file.bootstrap_archive.output_path
  source_code_hash = data.archive_file.bootstrap_archive.output_base64sha256
  timeout          = 120
 
  vpc_config {
    subnet_ids = var.subnet_ids
    security_group_ids = [aws_security_group.bootstrap.id]
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}
 
data "aws_lambda_invocation" "bootstrap" {
  function_name = aws_lambda_function.bootstrap.function_name
  input = <<JSON
{
  "endpoint": "${aws_eks_cluster.kuber_cluster.endpoint}",
  "token": "${data.aws_eks_cluster_auth.cluster.token}"
}
JSON
 
  depends_on = [aws_lambda_function.bootstrap]
}*/