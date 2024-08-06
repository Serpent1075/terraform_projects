 output "kinesis_arn" {
   value       = aws_kinesis_firehose_delivery_stream.extended_s3_stream.arn
   description = "kinesis delivery stream arn"
 }

  output "kinesis_name" {
   value       = aws_kinesis_firehose_delivery_stream.extended_s3_stream.name
   description = "kinesis delivery stream name"
 }