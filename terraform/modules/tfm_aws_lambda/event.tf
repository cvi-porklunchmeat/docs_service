# Event building based on vars

locals {
  sqs_find_queue  = var.sqs_enabled && var.event_sqs != null ? data.aws_sqs_queue.event_sqs[0].arn : null
  sqs_build_queue = var.sqs_enabled && var.event_sqs == null ? module.event_sqs[0].sqs_arn : null
}

# SQS events
data "aws_sqs_queue" "event_sqs" {
  count = var.event_sqs != null ? 1 : 0
  name  = var.event_sqs
}

module "event_sqs" {
  count  = var.sqs_enabled && var.event_sqs == null ? 1 : 0
  source = "./modules/event/sqs"
  #   enable        = lookup(var.event, "type", "") == "sqs" ? true : false
  namespace     = var.namespace
  function_arn  = aws_lambda_function.lambda.arn
  function_name = aws_lambda_function.lambda.function_name
}

resource "aws_lambda_event_source_mapping" "sqs_event_source" {
  count            = var.sqs_enabled && var.event_sqs != null ? 1 : 0
  event_source_arn = local.sqs_build_queue != null ? local.sqs_build_queue : local.sqs_find_queue
  function_name    = aws_lambda_function.lambda.arn
}

# S3 Bucket events
data "aws_s3_bucket" "event_bucket" {
  count  = var.s3_enabled && length(var.event_buckets) > 0 ? length(var.event_buckets) : 0
  bucket = var.event_buckets[count.index]
}

resource "aws_lambda_permission" "allow_bucket" {
  count         = var.s3_enabled && length(var.event_buckets) > 0 ? length(var.event_buckets) : 0
  statement_id  = "AllowExecutionFrom-${var.event_buckets[count.index]}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.event_bucket[count.index].arn
}

resource "aws_s3_bucket_notification" "s3_event_source" {
  count  = var.s3_enabled && length(var.event_buckets) > 0 ? length(var.event_buckets) : 0
  bucket = data.aws_s3_bucket.event_bucket[count.index].id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.s3_event_filter_prefix
    filter_suffix       = var.s3_event_filter_suffix
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# SNS events
resource "aws_sns_topic_subscription" "sns_event_source" {
  count     = var.sns_enabled ? 1 : 0
  topic_arn = var.event_sns_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "with_sns" {
  count         = var.sns_enabled ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.event_sns_arn
}