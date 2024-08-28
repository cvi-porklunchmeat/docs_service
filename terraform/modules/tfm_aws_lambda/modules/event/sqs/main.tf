resource "aws_sqs_queue" "lambda_sqs" {
  name = "${var.namespace}-${var.function_name}-sqs"
  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "lambda_event_source" {
  event_source_arn = aws_sqs_queue.lambda_sqs.arn
  function_name    = var.function_arn
}

