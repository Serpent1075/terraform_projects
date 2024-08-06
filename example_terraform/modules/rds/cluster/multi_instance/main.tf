provider "aws" {
  alias  = "primary"
  region = "ap-northeast-2"
}
#https://www.youtube.com/watch?v=XKPHbYe-fHQ
#엔진버전 업그레이드 시 파라미터그룹을 추가로 만들어주어야
#자연스럽게 새로운 파라미터 그룹을 적용할 수 있습니다.
#추가 생성이 없으면 기존의 파라미터 그룹을 업그레이드 도중 계속 사용하므로
#2번 적용시켜주어야합니다.
resource "aws_rds_cluster_parameter_group" "psql_clusger_pg" {
  name        = "${var.prefix}-rds-pg-cluster"
  family      = var.family
  description = "RDS default cluster parameter group"

/*
  parameter {
    name  = "rds.enable_plan_management"
    value = "1"
  } 해당 파라미터는 생성 후 수동으로 적용필요
*/
  parameter {
    name  = "apg_plan_mgmt.capture_plan_baselines"
    value = "automatic"
  }

  parameter {
    name  = "apg_plan_mgmt.use_plan_baselines"
    value = "true"
  }

  parameter {
    name  = "apg_plan_mgmt.max_plans"
    value = "10000"
  }

  parameter {
    name  = "apg_plan_mgmt.unapproved_plan_execution_threshold"
    value = "100"
  }

  parameter {
    name  = "random_page_cost"
    value = "1"
  }

  parameter {
    name  = "default_statistics_target"
    value = "256"
  }

  parameter {
    name  = "from_collapse_limit"
    value = "20"
  }

  parameter {
    name  = "join_collapse_limit"
    value = "20"
  }

  parameter {
    name = "log_statement"
    value = "mod"
  }

   parameter {
    name = "log_min_duration_statement"
    value = "100"
  }
}

resource "aws_db_parameter_group" "psql_instance_pg" {
  name   = "${var.prefix}-rds-instance-pg"
  family = var.family
  
  parameter {
    name  = "random_page_cost"
    value = "1"
  }

  parameter {
    name  = "default_statistics_target"
    value = "256"
  }

  parameter {
    name  = "from_collapse_limit"
    value = "20"
  }

  parameter {
    name  = "join_collapse_limit"
    value = "20"
  }
  parameter {
    name = "log_statement"
    value = "mod"
  }

  parameter {
    name = "log_min_duration_statement"
    value = "100"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.prefix}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.prefix} DB subnet group"
  }
}

resource "aws_rds_cluster" "rds_cluster" {
  provider                  = aws.primary
  cluster_identifier = "${var.prefix}-rds-cluster"
  engine             = var.engine
  engine_mode        = "provisioned"
  engine_version     = var.psqlversion
  database_name      = var.database_name
  master_username    = var.adminname
  master_password    = var.password
  preferred_maintenance_window = var.maintenance_date
  port = var.psqlport
  allow_major_version_upgrade = true
  deletion_protection = false
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.psql_clusger_pg.name
  db_instance_parameter_group_name = aws_db_parameter_group.psql_instance_pg.name
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  //global_cluster_identifier = aws_rds_global_cluster.global_cluster.id
  enabled_cloudwatch_logs_exports = ["postgresql"]
  skip_final_snapshot = true
  final_snapshot_identifier = "${var.prefix}-final-snapshot"
  storage_encrypted = true
  kms_key_id = var.kms_arn
  vpc_security_group_ids = var.vpc_security_group_ids

  lifecycle {
    ignore_changes = [global_cluster_identifier]
  }
}

resource "aws_rds_cluster_instance" "rds_cluster_instance" {
  provider                  = aws.primary
  identifier         = "${var.prefix}-writer-instance"
  cluster_identifier = aws_rds_cluster.rds_cluster.id
  instance_class     = var.writer_instance_class
  engine             = var.engine
  engine_version     = var.psqlversion
  preferred_maintenance_window = var.maintenance_date
  performance_insights_enabled = true
  performance_insights_kms_key_id = var.kms_arn
  apply_immediately = true
  db_parameter_group_name = aws_rds_cluster.rds_cluster.db_instance_parameter_group_name
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
}

resource "aws_rds_cluster_instance" "rds_cluster_instance_reader" {
  count              = 1
  identifier         = "${var.prefix}-reader-instance"
  provider                  = aws.primary
  cluster_identifier = aws_rds_cluster.rds_cluster.id
  instance_class     = var.reader_instance_class
  engine             = var.engine
  engine_version     = var.psqlversion
  preferred_maintenance_window = var.maintenance_date
  performance_insights_enabled = true
  performance_insights_kms_key_id = var.kms_arn
  apply_immediately = true
  db_parameter_group_name = aws_rds_cluster.rds_cluster.db_instance_parameter_group_name
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
}
/*
resource "aws_rds_cluster_instance" "rds_cluster_instance_reader2" {
  provider                  = aws.primary
  cluster_identifier = aws_rds_cluster.rds_cluster.id
  instance_class     = var.reader_instance_class
  engine             = var.engine
  engine_version     = var.psqlversion
  preferred_maintenance_window = var.maintenance_date
  performance_insights_enabled = true
  apply_immediately = true
  db_parameter_group_name = aws_rds_cluster.rds_cluster.db_instance_parameter_group_name
  db_subnet_group_name = aws_db_subnet_group.rds_sb_group.name
}
*/
#Global 제거시 기존 인스턴스 및 클러스터는 그대로(삭제및 생성되지 않음)
#Global 생성 시 비어있는 상태이므로 리전을 기본리전을 추가 
#또는 아래와 같이 Source_db_cluster_identifier를 통해 기존의 클러스터에서
#리전 정보를 따와야한다. 
#기존 클러스터에 글로벌 추가 시 기존 클러스터를 삭제하지 않고 그대로 붙여짐
/*
resource "aws_rds_global_cluster" "global_cluster" {
  global_cluster_identifier = "${var.prefix}-global"
  #engine                    = var.engine
  #engine_version            = var.psqlversion
  #database_name             = var.database_name
  force_destroy             = true
  #기존의 클러스터에 연결할 경우 필요, 새 클러스터 생성시 위 주석을 제거하고,
  #아래의 source_db_identifier를 주석처리해서 사용
  source_db_cluster_identifier = aws_rds_cluster.rds_cluster.arn
  # NOTE: Using this DB Cluster to create a Global Cluster, the
  # global_cluster_identifier attribute will become populated and
  # Terraform will begin showing it as a difference. Do not configure:
  # global_cluster_identifier = aws_rds_global_cluster.example.id
  # as it creates a circular reference. Use ignore_changes instead.
 
}
*/ 


/*#Serverlessv2
resource "aws_rds_cluster" "rds_cluster" {
  provider                  = aws.primary
  cluster_identifier = "${var.prefix}-cluster"
  engine             = aws_rds_global_cluster.global_cluster.engine
  engine_mode        = "provisioned"
  engine_version     = aws_rds_global_cluster.global_cluster.engine_version
  database_name      = var.database_name
  master_username    = var.adminname
  master_password    = var.password
  preferred_maintenance_window = "tue:18:30-tue:19:30"
  port = var.psqlport
  allow_major_version_upgrade = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.psql_clusger_pg.name
  db_instance_parameter_group_name = aws_db_parameter_group.psql_instance_pg.name
  db_subnet_group_name = aws_db_subnet_group.rds_sb_group.name
  enabled_cloudwatch_logs_exports = ["postgresql"]
  skip_final_snapshot = true
  final_snapshot_identifier = "${var.prefix}-final-snapshot"
  storage_encrypted = true
  kms_key_id = var.kms_arn
  vpc_security_group_ids = var.vpc_security_group_ids

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
  
  lifecycle {
    ignore_changes = [global_cluster_identifier]
  }

}

resource "aws_rds_cluster_instance" "rds_cluster_instance" {
  provider                  = aws.primary
  cluster_identifier = aws_rds_cluster.rds_cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.rds_cluster.engine
  engine_version     = aws_rds_cluster.rds_cluster.engine_version
  db_subnet_group_name = aws_db_subnet_group.rds_sb_group.name
}
*/
