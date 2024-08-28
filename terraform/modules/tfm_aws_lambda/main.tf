data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

locals {
  ntag = "${var.namespace}-${var.lambda_function_name}"
}

resource "aws_lambda_function" "lambda" {
  function_name = var.lambda_function_name
  description   = var.description
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  layers        = var.lambda_layers

  role = aws_iam_role.lambda.arn

  package_type = var.package_type

  s3_bucket         = var.deploy_bucket_id
  s3_key            = var.lambda_zip
  s3_object_version = var.lambda_zip_version

  image_uri = var.image_uri

  tags = merge(var.tags, tomap({ "Name" = format("%s", local.ntag) }))

  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null && var.vpc_security_group_ids != null ? [true] : []
    content {
      security_group_ids = var.vpc_security_group_ids
      subnet_ids         = var.vpc_subnet_ids
    }
  }

  dynamic "environment" {
    for_each = length(var.env_vars) < 1 ? [] : [var.env_vars]
    content {
      variables = environment.value.variables
    }
  }

  dynamic "dead_letter_config" {
    for_each = aws_sqs_queue.dlq
    content {
      target_arn = dead_letter_config.value.arn
    }
  }

}
