output "bucket-id" {
    value = aws_s3_bucket.lambdaedge_s3.id
}
output "bucket-name" {
    value = aws_s3_bucket.lambdaedge_s3.bucket
}
output "bucket-arn" {
    value = aws_s3_bucket.lambdaedge_s3.arn
}
output "bucket-domain-name" {
    value = aws_s3_bucket.lambdaedge_s3.bucket_domain_name
}
