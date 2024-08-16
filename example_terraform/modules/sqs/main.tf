resource "aws_sqs_queue" "terraform_queue" {
  name                      = "${var.prefix}-queue.fifo" # name of fifo queue should end with fifo
  fifo_queue                  = true
  content_based_deduplication = true
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  kms_master_key_id                 = var.kms_keyid
  kms_data_key_reuse_period_seconds = 300
 
  tags = {
    Environment = "production"
  }
}

resource "aws_sqs_queue_policy" "terraform_queue_policy" {
  queue_url = aws_sqs_queue.terraform_queue.id

  policy = <<POLICY
        {
            "Version": "2012-10-17",
            "Id": "sqspolicy",
            "Statement": [
                {
                "Sid": "First",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "sqs:SendMessage",
                "Resource": "${aws_sqs_queue.terraform_queue.arn}"
                }
            ]
        }
    POLICY
}


resource "aws_sqs_queue" "terraform_queue_deadletter" {
  name = "${var.prefix}-deadletter-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.terraform_queue.arn]
  })
}

resource "aws_sqs_queue_redrive_policy" "q" {
  queue_url = aws_sqs_queue.terraform_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
    maxReceiveCount     = 4
  })
}
