resource "aws_cloudwatch_log_group" "eventbridge_events" {
  name = "/aws/events/${local.project_name}-eventbridge-events"
}

# data "aws_iam_policy_document" "eventbridge_events" {
#   statement {
#     actions = [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#       "logs:PutLogEventsBatch",
#     ]

#     resources = [aws_cloudwatch_log_group.eventbridge_events.arn]

#     principals {
#       identifiers = ["events.amazonaws.com"]
#       type        = "Service"
#     }
#   }
# }

# resource "aws_cloudwatch_log_resource_policy" "eventbridge_events" {
#   policy_document = data.aws_iam_policy_document.eventbridge_events.json
#   policy_name     = "${local.project_name}-eventbridge-events"
# }
