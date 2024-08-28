locals {
  s3_permissions = var.deploy_bucket_arn != null ? [var.deploy_bucket_arn, "${var.deploy_bucket_arn}/*", ] : ["*"]
}

resource "aws_iam_role" "lambda" {
  name = var.role_name
  #   assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role_policy_document.json}"
  assume_role_policy = var.inline_policy == null ? data.aws_iam_policy_document.lambda_inline_policy.json : var.inline_policy
}

data "aws_iam_policy_document" "lambda_inline_policy" {
  statement {
    actions = ["sts:AssumeRole", ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.namespace}-${var.lambda_function_name}"
  path        = "/"
  description = "IAM policy for a lambda"
  policy      = var.deploy_bucket_arn != null ? data.aws_iam_policy_document.lambda_policy.json : data.aws_iam_policy_document.lambda_policy_container.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*", ]
  }

  statement {
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
    ]
    resources = ["*", ]
  }

  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = ["*", ]
  }

  statement {
    actions   = ["s3:*"]
    resources = local.s3_permissions
  }

  statement {
    actions = [
      "autoscaling:Describe*",
      "cloudwatch:*",
      "logs:*",
      "sns:*",
    ]
    resources = ["*", ]
  }

  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]
    resources = ["*", ]
  }
}

data "aws_iam_policy_document" "lambda_policy_container" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*", ]
  }

  statement {
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
    ]
    resources = ["*", ]
  }

  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = ["*", ]
  }

  statement {
    actions = [
      "autoscaling:Describe*",
      "cloudwatch:*",
      "logs:*",
      "sns:*",
    ]
    resources = ["*", ]
  }

  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]
    resources = ["*", ]
  }
}


# Policy for sqs dlq
resource "aws_iam_policy" "lambda_dlq_policy" {
  for_each    = aws_sqs_queue.dlq
  name        = "${var.namespace}-${var.lambda_function_name}-dlq"
  path        = "/"
  description = "IAM policy for a lambda dlq"
  policy      = data.aws_iam_policy_document.lambda_dlq_policy[each.key].json
}

data "aws_iam_policy_document" "lambda_dlq_policy" {
  for_each = aws_sqs_queue.dlq
  statement {
    actions = [
      "sqs:SendMessage"
    ]
    resources = [aws_sqs_queue.dlq[each.key].arn]
  }
}

# Policy attach for above
resource "aws_iam_role_policy_attachment" "lambda_dlq_policy_attachment" {
  for_each   = aws_sqs_queue.dlq
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_dlq_policy[each.key].arn
}

# Policy attach for above
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Policy attach for passed in Policy ARN
resource "aws_iam_role_policy_attachment" "var_policy_attachment" {
  count      = length(var.policy_arn)
  role       = aws_iam_role.lambda.name
  policy_arn = var.policy_arn[count.index]
}
