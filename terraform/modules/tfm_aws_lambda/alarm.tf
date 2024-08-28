resource "aws_cloudwatch_metric_alarm" "lambda-exectime-alarm" {
  alarm_name          = "${var.lambda_function_name}-execution-time"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = aws_lambda_function.lambda.timeout / 60 # number of periods to evaluate
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "60" # seconds
  statistic           = "Maximum"
  threshold           = aws_lambda_function.lambda.timeout * 1000 * 0.75 # datapoint to change alarm state
  datapoints_to_alarm = 1
  alarm_description   = "Lambda Execution Time"
  treat_missing_data  = "ignore"

  insufficient_data_actions = [
    aws_sns_topic.alarms.arn,
  ]

  alarm_actions = [
    aws_sns_topic.alarms.arn,
  ]

  ok_actions = [
    aws_sns_topic.alarms.arn,
  ]

  dimensions = {
    FunctionName = aws_lambda_function.lambda.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda-errors-alarm" {
  alarm_name          = "${var.lambda_function_name}-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = aws_lambda_function.lambda.timeout / 60
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "Lambda Errors"
  treat_missing_data  = "ignore"
  datapoints_to_alarm = 1

  insufficient_data_actions = [
    aws_sns_topic.alarms.arn,
  ]

  alarm_actions = [
    aws_sns_topic.alarms.arn,
  ]

  ok_actions = [
    aws_sns_topic.alarms.arn,
  ]

  dimensions = {
    FunctionName = aws_lambda_function.lambda.function_name
  }
}