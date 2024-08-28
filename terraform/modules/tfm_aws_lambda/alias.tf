resource "aws_lambda_alias" "func_alias" {
  name             = var.lambda_function_name
  description      = var.description
  function_name    = aws_lambda_function.lambda.function_name
  function_version = try(aws_lambda_function.lambda.version, "$LATEST")
}
