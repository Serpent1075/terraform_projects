resource "aws_msk_scram_secret_association" "jhoh_tf" {
  cluster_arn     = aws_msk_cluster.jhoh-msk.arn
  secret_arn_list = [var.secret_arn]

  depends_on = [var.secret_arn]
}

resource "aws_msk_cluster" "jhoh-msk" {
  cluster_name           = "${var.prefix}-msk-cluster"
  kafka_version          = var.msk_version
  number_of_broker_nodes = 2
  configuration_info {
    arn = aws_msk_configuration.custom_template.arn
    revision = 1
  }

  broker_node_group_info {
    instance_type = "kafka.m5.large"
    client_subnets = var.subnet_ids
    storage_info {
      ebs_storage_info {
        volume_size = 1000
      }
    }
    security_groups = [var.sg_id]
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
    }
    encryption_at_rest_kms_key_arn = var.kms_key_arn
  }


  client_authentication {
    sasl {
      iam = true
      //scram = true
    }
    
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = var.log_group
      }
      firehose {
        enabled         = true
        delivery_stream = var.firehose_name
      }
      s3 {
        enabled = true
        bucket  = var.bucket_id
        prefix  = "logs/msk-"
      }
    }
  }

  tags = {
    foo = "bar"
  }

}

resource "aws_msk_configuration" "custom_template" {
  kafka_versions = [var.msk_version]
  name           = "${var.prefix}-configuration"

  server_properties = <<PROPERTIES
    auto.create.topics.enable=true
    default.replication.factor=2
    min.insync.replicas=2
    num.io.threads=8
    num.network.threads=5
    num.partitions=1
    num.replica.fetchers=2
    replica.lag.time.max.ms=30000
    socket.receive.buffer.bytes=102400
    socket.request.max.bytes=104857600
    socket.send.buffer.bytes=102400
    unclean.leader.election.enable=true
    zookeeper.session.timeout.ms=18000
    delete.topic.enable = true
    PROPERTIES
}

resource "aws_secretsmanager_secret_policy" "jhoh_msk_secret_policy" {
  secret_arn = var.secret_arn
  policy     = <<POLICY
  {
    "Version" : "2012-10-17",
    "Statement" : [ {
      "Sid": "AWSKafkaResourcePolicy",
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "kafka.amazonaws.com"
      },
      "Action" : "secretsmanager:getSecretValue",
      "Resource" : "${var.secret_arn}"
    } ]
  }
  POLICY
}