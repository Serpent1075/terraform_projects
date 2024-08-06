output "bucket_id" {
    value = aws_s3_bucket.cloudfront_s3.id
}
output "bucket_name" {
    value = aws_s3_bucket.cloudfront_s3.bucket
}
output "bucket_arn" {
    value = aws_s3_bucket.cloudfront_s3.arn
}
output "bucket_domain_name" {
    value = aws_s3_bucket.cloudfront_s3.bucket_domain_name
}
