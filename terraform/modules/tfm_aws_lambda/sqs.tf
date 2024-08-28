locals {
  dlq_name = ["${var.namespace}-${var.lambda_function_name}-dlq"]
}

resource "aws_sqs_queue" "lambda_sqs" {
  count = var.sqs_enabled == 1 ? 1 : 0
  name  = "${var.lambda_function_name}-sqs-${var.namespace}"
  tags  = var.tags
}

resource "aws_sqs_queue" "dlq" {
  for_each = { for dlq_name in local.dlq_name : dlq_name => { name : dlq_name } if var.enable_dlq }
  name     = each.value.name
  tags     = var.tags
}

data "aws_iam_policy_document" "lambda_dl_queue" {
  for_each = aws_sqs_queue.dlq
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [each.value.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_lambda_function.lambda.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "lambda_dl_queue" {
  for_each  = aws_sqs_queue.dlq
  queue_url = each.value.id
  policy    = data.aws_iam_policy_document.lambda_dl_queue[each.value.name].json
}
