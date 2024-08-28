# Make a topic for logs, this is NOT an eventing SNS topic, this is PURELY logging for the lambda.
resource "aws_sns_topic" "alarms" {
  name = "${var.lambda_function_name}-alerts"
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.alarms.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    sid = "__default_statement_ID"

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

    effect    = "Allow"
    resources = ["${aws_sns_topic.alarms.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }

  statement {
    sid       = "Allow ${var.lambda_function_name} CloudwatchEvents"
    actions   = ["sns:Publish"]
    resources = ["${aws_sns_topic.alarms.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
