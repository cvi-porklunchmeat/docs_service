resource "aws_iam_role" "pipe" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "pipes.amazonaws.com"
      }
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }
  })
}

resource "aws_iam_role_policy" "source" {
  role = aws_iam_role.pipe.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage",
        ],
        Resource = [
          aws_sqs_queue.sqs_to_pipe.arn
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "target" {
  role = aws_iam_role.pipe.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents",
        ],
        Resource = [
          module.eventbridge.eventbridge_bus_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
        ],
        Resource = [
          module.sqs_enrichment_function.arn
        ]
      }
    ]
  })
}

resource "aws_pipes_pipe" "sqs_to_eventbridge" {
  depends_on = [aws_iam_role_policy.source, aws_iam_role_policy.target]
  name       = "${local.project_name}-sqs_to_eventbridge"
  role_arn   = aws_iam_role.pipe.arn

  enrichment = module.sqs_enrichment_function.arn
  source     = aws_sqs_queue.sqs_to_pipe.arn
  target     = module.eventbridge.eventbridge_bus_arn

  source_parameters {}
  target_parameters {}
}
