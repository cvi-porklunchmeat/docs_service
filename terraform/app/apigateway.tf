########################################################
resource "aws_api_gateway_rest_api" "gateway_api" {
  name           = local.project_name
  description    = local.project_name
  api_key_source = "AUTHORIZER"
  body           = data.template_file.openapi.rendered
  policy         = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Principal": "*",
          "Action": "execute-api:Invoke",
          "Resource": [
              "*"
          ]
      },
      {
          "Effect": "Deny",
          "Principal": "*",
          "Action": "execute-api:Invoke",
          "Resource": [
              "*"
          ],
          "Condition" : {
              "StringNotEquals": {
                  "aws:SourceVpce": "${module.tfm_aws_network.vpce_outputs.execute-api.endpoints.execute-api.id}"
              }
          }
      }
  ]
}
EOF

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [module.tfm_aws_network.vpce_outputs.execute-api.endpoints.execute-api.id]
  }
}

resource "aws_api_gateway_usage_plan" "api_usage_plan" {
  name        = "${var.namespace}_usage_plan"
  description = "API Usage Plan for ${var.namespace}"

  api_stages {
    api_id = aws_api_gateway_rest_api.gateway_api.id
    stage  = aws_api_gateway_deployment.api_deploy.stage_name
  }

  throttle_settings {
    burst_limit = 50
    rate_limit  = 100
  }
}

resource "aws_api_gateway_api_key" "api_up_key" {
  name = "${local.project_name}_API_KEY"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.api_up_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_usage_plan.id
}

resource "aws_api_gateway_deployment" "api_deploy" {
  rest_api_id = aws_api_gateway_rest_api.gateway_api.id
  stage_name  = local.stage_name
  triggers = {
    redeployment = sha1(data.template_file.openapi.rendered)
  }
  lifecycle {
    create_before_destroy = true
  }
}

// Configure a policy to use for accessing APIs
// This may be consumed by end users, to setup
// IAM principals to talk to the APIs
resource "aws_iam_policy" "api_execute_admin" {
  name        = "api-execute-admin-${var.namespace}"
  description = "Provides access to all ${var.namespace} admin API endpoints"

  policy = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "execute-api:Invoke"
      ],
      "Resource": [
        "${aws_api_gateway_rest_api.gateway_api.execution_arn}/*"
      ]
    }
  ]
}
JSON
}

# pushes invoke_url out to an SSM store to save for later use by client account creations
resource "aws_ssm_parameter" "api_invoke_url" {
  name        = "${var.namespace}_api_invoke_url"
  description = "api gateway invoke url"
  type        = "String"
  value       = "https://${aws_api_gateway_rest_api.gateway_api.id}-${module.tfm_aws_network.vpce_outputs.execute-api.endpoints.execute-api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${local.stage_name}"
  overwrite   = "true"
}

# pushes api_usage_plan_id out to an SSM store to save for later use by client account creations
resource "aws_ssm_parameter" "api_usage_plan_id" {
  name        = "${var.namespace}_api_usage_plan_id"
  description = "api usage plan id"
  type        = "String"
  value       = aws_api_gateway_usage_plan.api_usage_plan.id
  overwrite   = "true"
}

# pushes api_key out to an SSM store to save for later use by client account creations
resource "aws_ssm_parameter" "api_key" {
  name        = "${var.namespace}_api_key"
  description = "api usage plan id"
  type        = "String"
  value       = aws_api_gateway_api_key.api_up_key.value
  overwrite   = "true"
}

# Log role (see iam.tf)
resource "aws_api_gateway_account" "api_account" {
  cloudwatch_role_arn = aws_iam_role.api_cloudwatch.arn
}

# General settings
resource "aws_api_gateway_method_settings" "general_settings" {
  rest_api_id = aws_api_gateway_rest_api.gateway_api.id
  stage_name  = aws_api_gateway_deployment.api_deploy.stage_name
  method_path = "*/*"
  settings {
    # Enable CloudWatch logging and metrics
    metrics_enabled    = true
    data_trace_enabled = true
    logging_level      = "INFO"
    # Limit the rate of calls to prevent abuse and unwanted charges
    throttling_rate_limit  = 100
    throttling_burst_limit = 50
  }
}

# Logging config
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "${var.namespace}-API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.gateway_api.id}/${aws_api_gateway_deployment.api_deploy.stage_name}"
  retention_in_days = 7
}
