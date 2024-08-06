output "endpoint" {
    value = aws_rds_cluster.rds_cluster.endpoint
}

output "reader-endpoint" {
    value = aws_rds_cluster.rds_cluster.reader_endpoint
}