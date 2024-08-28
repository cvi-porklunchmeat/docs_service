resource "aws_cloudwatch_log_group" "this_commands" {
  name              = "${local.short_name}/commands"
  kms_key_id        = aws_kms_key.this.arn
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "this_logs" {
  name              = "${local.short_name}/logs"
  kms_key_id        = aws_kms_key.this.arn
  retention_in_days = 365
}
