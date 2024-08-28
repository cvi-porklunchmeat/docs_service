output "sqs_arn" {
  value       = aws_sqs_queue.lambda_sqs.arn
  description = "ARN of the SQS created for the lambda"
}

output "sqs_id" {
  value       = aws_sqs_queue.lambda_sqs.id
  description = "ID of the SQS created for the lambda"
}