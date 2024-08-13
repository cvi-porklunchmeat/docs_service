resource "aws_sns_topic" "textract_results" {
  name = "${local.project_name}-textract-results"
}

resource "aws_sns_topic_policy" "textract_results" {
  arn    = aws_sns_topic.textract_results.arn
  policy = data.aws_iam_policy_document.textract_results.json
}

data "aws_iam_policy_document" "textract_results" {

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.textract_results.arn,
    ]

    sid = "__default_statement_ID"
  }
}

resource "aws_sns_topic_subscription" "textract_results" {
  topic_arn = aws_sns_topic.textract_results.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sqs_to_pipe.arn
}
