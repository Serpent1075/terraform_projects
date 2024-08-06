output "custom_plugin_arn" {
    value = aws_mskconnect_custom_plugin.debezium.arn
}

output "custom_plugin_latest_revision" {
    value = aws_mskconnect_custom_plugin.debezium.latest_revision
}