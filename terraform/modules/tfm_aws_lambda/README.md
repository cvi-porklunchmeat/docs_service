## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_event_sqs"></a> [event\_sqs](#module\_event\_sqs) | ./modules/event/sqs | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.function_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.lambda-errors-alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda-exectime-alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_iam_policy.lambda_dlq_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_dlq_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.var_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_alias.func_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_alias) | resource |
| [aws_lambda_event_source_mapping.sqs_event_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_function.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.with_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket_notification.s3_event_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_sns_topic.alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.sns_event_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.lambda_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.lambda_dl_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.lambda_dl_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_dlq_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_inline_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_policy_container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_s3_bucket.event_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_sqs_queue.event_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sqs_queue) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_bucket_arn"></a> [deploy\_bucket\_arn](#input\_deploy\_bucket\_arn) | ARN for lambda zip deployment S3 bucket | `any` | `null` | no |
| <a name="input_deploy_bucket_id"></a> [deploy\_bucket\_id](#input\_deploy\_bucket\_id) | ID value for lambda zip deployment S3 bucket | `any` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of what your Lambda Function does. | `string` | `""` | no |
| <a name="input_enable_dlq"></a> [enable\_dlq](#input\_enable\_dlq) | Create a dead letter queue for failed executions. | `bool` | `true` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | Environment (e.g. env variables) configuration for the Lambda function enable you to dynamically pass settings to your function code and libraries | `map(map(string))` | `{}` | no |
| <a name="input_event"></a> [event](#input\_event) | Event source configuration which triggers the Lambda function. Supported events: sqs | `map(string)` | `{}` | no |
| <a name="input_event_buckets"></a> [event\_buckets](#input\_event\_buckets) | Name of S3 bucket to monitor for events | `list(string)` | `[]` | no |
| <a name="input_event_sns"></a> [event\_sns](#input\_event\_sns) | The name of the pre-existing SNS topic to use if it exists | `string` | `null` | no |
| <a name="input_event_sns_arn"></a> [event\_sns\_arn](#input\_event\_sns\_arn) | The ARN of the pre-existing SNS topic to use if it exists | `string` | `null` | no |
| <a name="input_event_sqs"></a> [event\_sqs](#input\_event\_sqs) | The name of the pre-existing SQS queue to use if it exists | `string` | `null` | no |
| <a name="input_handler"></a> [handler](#input\_handler) | The function entrypoint in your code. | `any` | `null` | no |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | The URI of a container image in the Amazon ECR registry that contains the function code. | `any` | `null` | no |
| <a name="input_inline_policy"></a> [inline\_policy](#input\_inline\_policy) | Role inline policy json attached to the Lambda Function role. | `any` | `null` | no |
| <a name="input_lambda_function_name"></a> [lambda\_function\_name](#input\_lambda\_function\_name) | Name to be used on all the resources as identifier. | `any` | n/a | yes |
| <a name="input_lambda_layers"></a> [lambda\_layers](#input\_lambda\_layers) | S3 locations of the zips to be used for the lambda layer | `list(string)` | `[]` | no |
| <a name="input_lambda_zip"></a> [lambda\_zip](#input\_lambda\_zip) | Zip file name for deployment package.  Placeholder for resource construction. | `any` | `null` | no |
| <a name="input_lambda_zip_version"></a> [lambda\_zip\_version](#input\_lambda\_zip\_version) | (optional) The version of the lambda zip file - S3 bucket must have versioning enable to use this feature | `string` | `null` | no |
| <a name="input_logging_policy"></a> [logging\_policy](#input\_logging\_policy) | Name for logging policy in IAM for lambda. | `string` | `""` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Amount of memory in MB your Lambda Function can use at runtime. Default is 128MB | `number` | `128` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Name used for prefix to differentiate resources. | `string` | `"pr"` | no |
| <a name="input_package_type"></a> [package\_type](#input\_package\_type) | The type of deployment package. Valid values: Zip, Image | `string` | `"Zip"` | no |
| <a name="input_policy_arn"></a> [policy\_arn](#input\_policy\_arn) | IAM policy ARN attached to the Lambda Function role. | `list(string)` | `[]` | no |
| <a name="input_role"></a> [role](#input\_role) | This governs both who / what can invoke your Lambda Function, as well as what resources our Lambda Function has access to. See Lambda Permission Model for more details. | `string` | `""` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | The name of the IAM role which will be created for the Lambda Function. | `string` | `"LambdaRole"` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | The function runtime to use. (nodejs, nodejs4.3, nodejs6.10, nodejs8.10, java8, python2.7, python3.6, dotnetcore1.0, dotnetcore2.0, dotnetcore2.1, nodejs4.3-edge, go1.x) | `any` | `null` | no |
| <a name="input_s3_enabled"></a> [s3\_enabled](#input\_s3\_enabled) | Enables S3 bucket for eventing, requires event\_bucket var to be set | `bool` | `false` | no |
| <a name="input_s3_event_filter_prefix"></a> [s3\_event\_filter\_prefix](#input\_s3\_event\_filter\_prefix) | Prefix to use in filtering s3 events for invocations of the lambda function | `string` | `null` | no |
| <a name="input_s3_event_filter_suffix"></a> [s3\_event\_filter\_suffix](#input\_s3\_event\_filter\_suffix) | Suffix to use in filtering s3 events for invocations of the lambda function | `string` | `null` | no |
| <a name="input_sns_enabled"></a> [sns\_enabled](#input\_sns\_enabled) | Enables SNS for eventing to lambda | `bool` | `false` | no |
| <a name="input_sqs_enabled"></a> [sqs\_enabled](#input\_sqs\_enabled) | Enables SQS queue for eventing to lambda, builds SQS for event as well | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the object. | `map` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | The function timeout value for the amount of time it is allowed to execute.  Default is 3, upper limit is 900 seconds. | `any` | n/a | yes |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of security group ids when Lambda Function should run in the VPC. | `list(string)` | `null` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | List of subnet ids when Lambda Function should run in the VPC. Usually private or intra subnets. | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alias"></a> [alias](#output\_alias) | n/a |
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | The name of your Lambda Function. |
| <a name="output_invoke_arn"></a> [invoke\_arn](#output\_invoke\_arn) | The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws\_api\_gateway\_integration's uri |
| <a name="output_lambda_dlq"></a> [lambda\_dlq](#output\_lambda\_dlq) | Outputs the SQS queue created for the lambda function |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | The role created for the lambda function to access resources |
| <a name="output_last_modified"></a> [last\_modified](#output\_last\_modified) | The date this Lambda Function was last modified. |
| <a name="output_package_hash"></a> [package\_hash](#output\_package\_hash) | Base64-encoded representation of raw SHA-256 sum of the zip file, provided either via filename. |
| <a name="output_package_size"></a> [package\_size](#output\_package\_size) | The size in bytes of the function package file. |
| <a name="output_qualified_arn"></a> [qualified\_arn](#output\_qualified\_arn) | The Amazon Resource Name (ARN) identifying your Lambda Function Version. |
| <a name="output_role"></a> [role](#output\_role) | The Amazon Resource Name (ARN) identifying the IAM role attached to the Lambda Function. |
| <a name="output_version"></a> [version](#output\_version) | Latest published version of your Lambda Function. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
