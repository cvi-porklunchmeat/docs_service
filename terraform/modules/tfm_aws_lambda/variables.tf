variable "lambda_function_name" {
  description = "Name to be used on all the resources as identifier."
}

variable "description" {
  default     = ""
  description = "Description of what your Lambda Function does."
}

variable "handler" {
  description = "The function entrypoint in your code. "
  default     = null
}

variable "package_type" {
  description = "The type of deployment package. Valid values: Zip, Image"
  default     = "Zip"
}

variable "image_uri" {
  description = "The URI of a container image in the Amazon ECR registry that contains the function code. "
  default     = null
}

variable "runtime" {
  description = "The function runtime to use. (nodejs, nodejs4.3, nodejs6.10, nodejs8.10, java8, python2.7, python3.6, dotnetcore1.0, dotnetcore2.0, dotnetcore2.1, nodejs4.3-edge, go1.x)"
  default     = null
}

variable "enable_dlq" {
  description = "Create a dead letter queue for failed executions."
  default     = true
}

variable "timeout" {
  description = "The function timeout value for the amount of time it is allowed to execute.  Default is 3, upper limit is 900 seconds."
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime. Default is 128MB"
  default     = 128
}

variable "role" {
  description = "This governs both who / what can invoke your Lambda Function, as well as what resources our Lambda Function has access to. See Lambda Permission Model for more details."
  type        = string
  default     = ""
}

variable "role_name" {
  default     = "LambdaRole"
  description = "The name of the IAM role which will be created for the Lambda Function."
}

variable "logging_policy" {
  default     = ""
  description = "Name for logging policy in IAM for lambda."
}

variable "policy_arn" {
  type        = list(string)
  default     = []
  description = "IAM policy ARN attached to the Lambda Function role."
}

variable "inline_policy" {
  default     = null
  description = "Role inline policy json attached to the Lambda Function role."
}

variable "tags" {
  default     = {}
  description = "A mapping of tags to assign to the object."
}

variable "lambda_zip" {
  description = "Zip file name for deployment package.  Placeholder for resource construction."
  default     = null
}

variable "lambda_zip_version" {
  description = "(optional) The version of the lambda zip file - S3 bucket must have versioning enable to use this feature"
  type        = string
  default     = null
}

variable "namespace" {
  default     = "pr"
  description = "Name used for prefix to differentiate resources."
}

variable "deploy_bucket_arn" {
  description = "ARN for lambda zip deployment S3 bucket"
  default     = null
}

variable "deploy_bucket_id" {
  description = "ID value for lambda zip deployment S3 bucket"
  default     = null
}

variable "event" {
  description = "Event source configuration which triggers the Lambda function. Supported events: sqs"
  type        = map(string)
  default     = {}
}

variable "event_buckets" {
  description = "Name of S3 bucket to monitor for events"
  type        = list(string)
  default     = []
}

variable "event_sqs" {
  description = "The name of the pre-existing SQS queue to use if it exists"
  type        = string
  default     = null
}

variable "event_sns" {
  description = "The name of the pre-existing SNS topic to use if it exists"
  type        = string
  default     = null
}

variable "event_sns_arn" {
  description = "The ARN of the pre-existing SNS topic to use if it exists"
  type        = string
  default     = null
}

variable "s3_enabled" {
  description = "Enables S3 bucket for eventing, requires event_bucket var to be set"
  type        = bool
  default     = false
}

variable "sqs_enabled" {
  description = "Enables SQS queue for eventing to lambda, builds SQS for event as well"
  type        = bool
  default     = false
}

variable "sns_enabled" {
  description = "Enables SNS for eventing to lambda"
  type        = bool
  default     = false
}

variable "env_vars" {
  description = "Environment (e.g. env variables) configuration for the Lambda function enable you to dynamically pass settings to your function code and libraries"
  type        = map(map(string))
  default     = {}
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids when Lambda Function should run in the VPC. Usually private or intra subnets."
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of security group ids when Lambda Function should run in the VPC."
  type        = list(string)
  default     = null
}

variable "s3_event_filter_prefix" {
  description = "Prefix to use in filtering s3 events for invocations of the lambda function"
  type        = string
  default     = null
}

variable "s3_event_filter_suffix" {
  description = "Suffix to use in filtering s3 events for invocations of the lambda function"
  type        = string
  default     = null
}

variable "lambda_layers" {
  description = "S3 locations of the zips to be used for the lambda layer"
  type        = list(string)
  default     = []
}
