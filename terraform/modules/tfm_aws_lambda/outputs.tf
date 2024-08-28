output "arn" {
  value       = aws_lambda_function.lambda.arn
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
}

output "invoke_arn" {
  value       = aws_lambda_function.lambda.invoke_arn
  description = "The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws_api_gateway_integration's uri"
}

output "qualified_arn" {
  value       = aws_lambda_function.lambda.qualified_arn
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function Version."
}

output "lambda_dlq" {
  value       = aws_sqs_queue.dlq
  description = "Outputs the SQS queue created for the lambda function"
}

output "version" {
  value       = aws_lambda_function.lambda.version
  description = "Latest published version of your Lambda Function."
}

output "last_modified" {
  value       = aws_lambda_function.lambda.last_modified
  description = "The date this Lambda Function was last modified."
}

output "role" {
  value       = aws_iam_role.lambda.arn
  description = "The Amazon Resource Name (ARN) identifying the IAM role attached to the Lambda Function."
}

output "package_size" {
  value       = aws_lambda_function.lambda.source_code_size
  description = "The size in bytes of the function package file."
}

output "package_hash" {
  value       = aws_lambda_function.lambda.source_code_hash
  description = "Base64-encoded representation of raw SHA-256 sum of the zip file, provided either via filename."
}

output "function_name" {
  value       = aws_lambda_function.lambda.function_name
  description = "The name of your Lambda Function."
}

output "lambda_role_arn" {
  value       = aws_iam_role.lambda.arn
  description = "The role created for the lambda function to access resources"
}

# output "subnet_ids" {
#   value = aws_lambda_function.lambda.security_group_ids
# }

# output "sg_ids" {
#   value = aws_lambda_function.lambda.subnet_ids
# }

output "vpc_id" {
  value = aws_lambda_function.lambda.vpc_config[*].vpc_id
}

output "alias" {
  value = aws_lambda_alias.func_alias
}

output "lambda_alarm_sns_arn" {
  value       = aws_sns_topic.alarms.arn
  description = "The Amazon Resource Name (ARN) identifying the SNS topic associated with Lambda Alarms."
}
