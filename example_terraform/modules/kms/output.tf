output "kms-key-id" {
    value = aws_kms_key.kms-key.id
}

output "kms-key-keyid" {
    value = aws_kms_key.kms-key.key_id
}

output "kms-key-arn" {
    value = aws_kms_key.kms-key.arn
}

output "replica-kms-key-id" {
    value = aws_kms_replica_key.replica.id
}

output "replica-kms-key-arn" {
    value = aws_kms_replica_key.replica.arn
}

