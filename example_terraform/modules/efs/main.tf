resource "aws_efs_access_point" "efs_access_point" {
  file_system_id = aws_efs_file_system.efs.id
}

resource "aws_efs_file_system" "efs" {

  encrypted = true
  kms_key_id = var.kms_key_arn
  performance_mode = "generalPurpose" #maxIO
  tags = {
    Name = "${var.prefix}-efs"
  }
}

resource "aws_efs_mount_target" "efs-tg-a" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = var.pri_sub_a_id
  security_groups = var.efs-sg
}

resource "aws_efs_mount_target" "efs-tg-b" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = var.pri_sub_b_id
  security_groups = var.efs-sg
}