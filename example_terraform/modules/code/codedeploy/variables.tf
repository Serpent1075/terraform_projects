variable "prefix" {
  description = "Prefix of resource"
  type = string
}

variable "iam_arn" {
    description = "IAM for the codedeploy"
    type = string
}

variable "tg_name" {
    description = "Target Group name for the codedeploy"
    type = string
}

variable "asg_name" {
     description = "AutoScaling Group name for the codedeploy"
    type = list(string)
}