
resource "aws_elasticache_parameter_group" "parameter_group" {
  name   = "${var.prefix}-redis-params"
  family = var.family

  parameter {
    name = "cluster-enabled"
    value = "yes"
  }
}

resource "aws_elasticache_subnet_group" "sb_group" {
  name       = "${var.prefix}-cache-subnet"
  subnet_ids = var.subnet_ids
}


resource "aws_elasticache_replication_group" "elasticache_rep_group" {
  replication_group_id          = "${var.prefix}-elasticache-replication"
  description = "elasticache replication"
  node_type                     = var.node_type
  port                          = var.redisport
  apply_immediately             = true
  auto_minor_version_upgrade    = false
  maintenance_window            = var.maintenance_date
  snapshot_window               = "01:00-02:00"
  num_node_groups              = 1
  replicas_per_node_group       = 1
  parameter_group_name = aws_elasticache_parameter_group.parameter_group.name
  subnet_group_name = aws_elasticache_subnet_group.sb_group.name
  automatic_failover_enabled = true
  security_group_ids = var.sg_group_ids
  log_delivery_configuration {
    destination      = var.loggroup-name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }
}

