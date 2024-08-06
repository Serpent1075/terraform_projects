output "bucket-id" {
    value = aws_s3_bucket.log_bucket.id
}
output "bucket-name" {
    value = aws_s3_bucket.log_bucket.bucket
}
output "bucket-arn" {
    value = aws_s3_bucket.log_bucket.arn
}
output "bucket-domain-name" {
    value = aws_s3_bucket.log_bucket.bucket_domain_name
}
