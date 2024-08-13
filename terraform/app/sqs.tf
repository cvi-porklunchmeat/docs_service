# Dead letter queues
resource "aws_sqs_queue" "start_textract_lambda_dl_queue" {
  name = "${local.project_name}-start-textract-lambda-dl-queue"
}

resource "aws_sqs_queue" "retrieve_textract_lambda_dl_queue" {
  name = "${local.project_name}-retrieve-textract-lambda-dl-queue"
}

resource "aws_sqs_queue" "push_to_opensearch_dl_queue" {
  name = "${local.project_name}-push-to-opensearch-lambda-dl-queue"
}

# Dead letter queue permissions

data "aws_iam_policy_document" "start_textract_lambda_dl_queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.start_textract_lambda_dl_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.eventbridge.eventbridge_rule_arns.start_textract]
    }
  }
}

resource "aws_sqs_queue_policy" "start_textract_lambda_dl_queue" {
  queue_url = aws_sqs_queue.start_textract_lambda_dl_queue.id
  policy    = data.aws_iam_policy_document.start_textract_lambda_dl_queue.json
}

data "aws_iam_policy_document" "retrieve_textract_lambda_dl_queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.retrieve_textract_lambda_dl_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.eventbridge.eventbridge_rule_arns.retrieve_textract]
    }
  }
}

resource "aws_sqs_queue_policy" "retrieve_textract_lambda_dl_queue" {
  queue_url = aws_sqs_queue.retrieve_textract_lambda_dl_queue.id
  policy    = data.aws_iam_policy_document.retrieve_textract_lambda_dl_queue.json
}

data "aws_iam_policy_document" "push_to_opensearch_dl_queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.push_to_opensearch_dl_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.eventbridge.eventbridge_rule_arns.push_to_opensearch]
    }
  }
}

resource "aws_sqs_queue_policy" "push_to_opensearch_dl_queue" {
  queue_url = aws_sqs_queue.push_to_opensearch_dl_queue.id
  policy    = data.aws_iam_policy_document.push_to_opensearch_dl_queue.json
}


# Queues
resource "aws_sqs_queue" "sqs_to_pipe" {
  name = "${local.project_name}-s3-to-pipe"
}

# Permissions for resources to publish to SQS queues
data "aws_iam_policy_document" "eventbridge_pipe" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.sqs_to_pipe.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.documents.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.sqs_to_pipe.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.textract_results.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# Attach permissions to SQS queues

resource "aws_sqs_queue_policy" "sqs_to_pipe" {
  queue_url = aws_sqs_queue.sqs_to_pipe.id
  policy    = data.aws_iam_policy_document.eventbridge_pipe.json
}
