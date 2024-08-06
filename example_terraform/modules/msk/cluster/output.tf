output "zookeeper_connect_string" {
  value = aws_msk_cluster.jhoh-msk.zookeeper_connect_string
}

output "bootstrap_brokers_sasl_iam" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.jhoh-msk.bootstrap_brokers_sasl_iam
}

output "msk_secret_policy_arn" {
  description = "MSK Secret Manager Policy ARN"
  value = aws_secretsmanager_secret_policy.jhoh_msk_secret_policy.secret_arn
}