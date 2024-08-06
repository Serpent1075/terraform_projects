resource "aws_mskconnect_connector" "example" {
  name = "${var.prefix}-connector"

  kafkaconnect_version = "2.7.1"

  capacity {
    autoscaling {
      mcu_count        = 1
      min_worker_count = 1
      max_worker_count = 2

      scale_in_policy {
        cpu_utilization_percentage = 20
      }

      scale_out_policy {
        cpu_utilization_percentage = 80
      }
    }
  }

  connector_configuration = {
    "connector.class" = "io.debezium.connector.postgresql.PostgresConnector"
    "tasks.max"       = "1"
    "database.hostname" = "debezium-cdc.fac07b9701a2.ap-south-1.rds.amazonaws.com"
    "database.port" = 5432
    "database.dbname" = "jhoh-tf-database"
    "database.user" = "user"
    "database.password" = "password"
    "database.history.kafka.bootstrap.servers" = var.bootstrap_tls
    "database.server.id" = 1
    "database.server.name" = "debezium-cdc"
    "database.whitelist" = "ecommerce"
    "database.history.kafka.topic" = "dbhistory.ecommerce"
    "include.schema.changes" = true
    "key.converter" = "org.apache.kafka.connect.json.JsonConverter"
    "value.converter" = "org.apache.kafka.connect.json.JsonConverter"
  }
 
  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = var.bootstrap_tls

      vpc {
        security_groups = [var.sg_id]
        subnets         = var.subnet_ids
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "NONE" // IAM NONE
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.debezium.arn
      revision = aws_mskconnect_custom_plugin.debezium.latest_revision
    }
  }

  service_execution_role_arn = var.connector_execution_iam_arn
}

resource "aws_s3_object" "debezium" {
  bucket = var.bucket_id
  key    = "test/debezium.zip"
}

resource "aws_mskconnect_custom_plugin" "debezium" {
  name         = "${var.prefix}-debezium"
  content_type = "ZIP"
  location {
    s3 {
      bucket_arn = var.bucket_arn
      file_key   = aws_s3_object.debezium.key
    }
  }
}

resource "aws_mskconnect_worker_configuration" "example" {
  name                    = "example"
  properties_file_content = <<EOT
    key.converter=org.apache.kafka.connect.storage.StringConverter
    value.converter=org.apache.kafka.connect.storage.StringConverter
    EOT
}