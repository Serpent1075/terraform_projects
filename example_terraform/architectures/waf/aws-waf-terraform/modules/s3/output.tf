output "bucket_id" {
    value = aws_s3_bucket.region.id
}
output "bucket_name" {
    value = aws_s3_bucket.region.bucket
}
output "bucket_arn" {
    value = aws_s3_bucket.region.arn
}
output "bucket_domain_name" {
    value = aws_s3_bucket.region.bucket_domain_name
}
