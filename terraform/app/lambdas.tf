data "aws_s3_bucket" "deploy_bucket" {
  bucket = var.deploy_bucket_name
}

########################################################################
# Frontend (used to return index.html)
########################################################################

# resource "aws_lambda_permission" "frontend" {
#   statement_id  = "AllowExecutionFromALB"
#   action        = "lambda:InvokeFunction"
#   function_name = module.frontend_lambda_function.function_name
#   principal     = "elasticloadbalancing.amazonaws.com"
#   source_arn    = aws_lb_target_group.frontend_lambda.arn
# }

# data "aws_s3_object" "frontend" {
#   bucket = var.deploy_bucket_name
#   key    = "lambda/frontend.zip"
# }

# module "frontend_lambda_function" {
#   source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
#   lambda_function_name = "${local.project_name}-frontend"
#   timeout              = 300
#   runtime              = "python3.10"
#   policy_arn           = tolist([aws_iam_policy.frontend_lambda_policy.arn])
#   deploy_bucket_id     = var.deploy_bucket_name
#   deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
#   lambda_zip_version   = data.aws_s3_object.frontend.version_id
#   lambda_zip           = "lambda/frontend.zip"
#   handler              = "func.handler"
#   namespace            = var.namespace
#   role_name            = "${local.project_name}-frontend-role"

#   env_vars = {
#     variables = {
#       FRONTEND_BUCKET_NAME = aws_s3_bucket.frontend.bucket
#     }
#   }
# }

########################################################################
# BACKEND API - AUTH
########################################################################

# Authorizer (protects all secure API endpoints)

data "aws_s3_object" "authorizer" {
  bucket = var.deploy_bucket_name
  key    = "lambda/authorizer.zip"
}

module "authorizer_lambda_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  lambda_function_name = "${local.project_name}-authorizer"
  timeout              = 300
  runtime              = "python3.10"
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.authorizer.version_id
  lambda_zip           = "lambda/authorizer.zip"
  handler              = "func.handler"
  namespace            = var.namespace
  role_name            = "${local.project_name}-authorizer-role"
  inline_policy        = data.aws_iam_policy_document.custom_assume_role.json
  policy_arn           = [aws_iam_policy.custom_permits.arn]
  enable_dlq           = true

  env_vars = {
    variables = {
      OKTA_CLIENT_SECRET_ID     = aws_secretsmanager_secret.okta.arn
      OKTA_CLIENT_SECRET_REGION = data.aws_region.current.name
      ALLOWED_ORIGIN            = local.env_frontend_host
      #API_GATEWAY_ID            = aws_api_gateway_rest_api.gateway_api.id
      API_GATEWAY_REGION = data.aws_region.current.name
      API_GATEWAY_STAGE  = var.namespace
    }
  }
}

resource "aws_lambda_permission" "auth_authorize_allow_api_gateway" {
  function_name = module.auth_authorize_lambda_function.function_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gateway_api.execution_arn}/*/*"
}

data "aws_s3_object" "auth_authorize" {
  bucket = var.deploy_bucket_name
  key    = "lambda/auth_authorize.zip"
}

module "auth_authorize_lambda_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  lambda_function_name = "${var.namespace}-auth_authorize"
  timeout              = 300
  runtime              = "python3.10"
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.auth_authorize.version_id
  lambda_zip           = "lambda/auth_authorize.zip"
  handler              = "func.handler"
  namespace            = var.namespace
  role_name            = "${var.namespace}-auth_authorize-role"
  policy_arn           = [aws_iam_policy.custom_permits.arn]
  enable_dlq           = true

  env_vars = {
    variables = {
      OKTA_CLIENT_SECRET_ID     = aws_secretsmanager_secret.okta.arn
      OKTA_CLIENT_SECRET_REGION = data.aws_region.current.name
      ALLOWED_ORIGIN            = local.env_frontend_host
    }
  }
}

# Token endpoint (Takes temp user auth code, and requests user auth tokens from Okta with it)
resource "aws_lambda_permission" "auth_token_allow_api_gateway" {
  function_name = module.auth_token_lambda_function.function_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gateway_api.execution_arn}/*/*"
}

data "aws_s3_object" "auth_token" {
  bucket = var.deploy_bucket_name
  key    = "lambda/auth_token.zip"
}

module "auth_token_lambda_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  lambda_function_name = "${var.namespace}-auth_token"
  timeout              = 300
  runtime              = "python3.10"
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.auth_token.version_id
  lambda_zip           = "lambda/auth_token.zip"
  handler              = "func.handler"
  namespace            = var.namespace
  role_name            = "${local.project_name}-auth_token-role"
  policy_arn           = [aws_iam_policy.custom_permits.arn]
  enable_dlq           = true

  env_vars = {
    variables = {
      OKTA_CLIENT_SECRET_ID     = aws_secretsmanager_secret.okta.arn
      OKTA_CLIENT_SECRET_REGION = data.aws_region.current.name
      ALLOWED_ORIGIN            = local.env_frontend_host
    }
  }
}

########################################################################
# BACKEND API - ENDPOINTS
########################################################################

# Local document upload
resource "aws_lambda_permission" "local_document_upload" {
  function_name = module.local_document_upload_lambda_function.function_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gateway_api.execution_arn}/*/*"
}

data "aws_s3_object" "local_document_upload" {
  bucket = var.deploy_bucket_name
  key    = "lambda/local_document_upload.zip"
}

module "local_document_upload_lambda_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  namespace            = var.namespace
  runtime              = "python3.10"
  timeout              = 300
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.local_document_upload.version_id
  lambda_zip           = "lambda/local_document_upload.zip"
  policy_arn           = tolist([aws_iam_policy.lambda_policy.arn, aws_iam_policy.custom_permits_local_upload_lambda.arn])
  handler              = "app.lambda_handler"
  lambda_function_name = "${local.project_name}-local-document-upload"
  role_name            = "${local.project_name}-local-document-upload-role"
  inline_policy        = data.aws_iam_policy_document.lambda-assume-role-policy.json
  enable_dlq           = true

  env_vars = {
    variables = {
      NAMESPACE          = var.namespace,
      REGION             = data.aws_region.current.name
      ALLOWED_ORIGIN     = local.env_frontend_host
      DOCUMENT_BUCKET    = aws_s3_bucket.documents.id
      DYNAMODB_TABLE_ID  = module.tfm_aws_dynamodb.dynamodb_table_id,
      DYNAMODB_TABLE_ARN = module.tfm_aws_dynamodb.dynamodb_table_arn
    }
  }
}

# Fetch And Store Lambda
resource "aws_lambda_permission" "fetch_and_download" {
  function_name = module.fetch_and_download_lambda_function.function_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gateway_api.execution_arn}/*/*"
}

data "aws_s3_object" "fetch_and_download" {
  bucket = var.deploy_bucket_name
  key    = "lambda/fetch_and_download.zip"
}

module "fetch_and_download_lambda_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  namespace            = var.namespace
  runtime              = "python3.10"
  timeout              = 300
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.fetch_and_download.version_id
  lambda_zip           = "lambda/fetch_and_download.zip"
  policy_arn           = tolist([aws_iam_policy.lambda_policy.arn, aws_iam_policy.custom_permits_fetch_download_lambda.arn])
  handler              = "app.lambda_handler"
  lambda_function_name = "${local.project_name}-fetch-and-download"
  role_name            = "${local.project_name}-fetch-and-download-role"
  inline_policy        = data.aws_iam_policy_document.lambda-assume-role-policy.json
  enable_dlq           = true
  lambda_layers        = ["arn:aws:lambda:${data.aws_region.current.name}:017000801446:layer:AWSLambdaPowertoolsPythonV2:32"]

  env_vars = {
    variables = {
      NAMESPACE       = var.namespace,
      REGION          = data.aws_region.current.name
      DOCUMENT_BUCKET = aws_s3_bucket.documents.id
    }
  }
}

# Generate Document Url Lambda
resource "aws_lambda_permission" "generate_document_url" {
  function_name = module.generate_document_url_lambda_function.function_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gateway_api.execution_arn}/*/*"
}

data "aws_s3_object" "generate_document_url" {
  bucket = var.deploy_bucket_name
  key    = "lambda/generate_document_url.zip"
}

module "generate_document_url_lambda_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  namespace            = var.namespace
  runtime              = "python3.10"
  timeout              = 300
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.generate_document_url.version_id
  lambda_zip           = "lambda/generate_document_url.zip"
  policy_arn           = tolist([aws_iam_policy.lambda_policy.arn, aws_iam_policy.custom_permits_generate_document_url_lambda.arn])
  handler              = "app.lambda_handler"
  lambda_function_name = "${local.project_name}-generate-document-url"
  role_name            = "${local.project_name}-generate-document-url-role"
  inline_policy        = data.aws_iam_policy_document.lambda-assume-role-policy.json
  enable_dlq           = true
  lambda_layers        = ["arn:aws:lambda:${data.aws_region.current.name}:017000801446:layer:AWSLambdaPowertoolsPythonV2:32"]

  env_vars = {
    variables = {
      NAMESPACE       = var.namespace,
      REGION          = data.aws_region.current.name
      DOCUMENT_BUCKET = aws_s3_bucket.documents.id
    }
  }
}

# Start Textract Lambda
resource "aws_lambda_permission" "start_textract_allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.start_textract_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge.eventbridge_rule_arns.start_textract
}

data "aws_s3_object" "start_textract" {
  bucket = var.deploy_bucket_name
  key    = "lambda/start_textract.zip"
}

module "start_textract_lambda_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  namespace            = var.namespace
  runtime              = "python3.10"
  timeout              = 300
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.start_textract.version_id
  lambda_zip           = "lambda/start_textract.zip"
  policy_arn           = tolist([aws_iam_policy.lambda_policy.arn, aws_iam_policy.custom_permit_textract.arn])
  handler              = "app.lambda_handler"
  lambda_function_name = "${local.project_name}-start-textract"
  role_name            = "${local.project_name}-start-textract-role"
  inline_policy        = data.aws_iam_policy_document.lambda-assume-role-policy.json
  enable_dlq           = true

  env_vars = {
    variables = {
      NAMESPACE         = var.namespace,
      REGION            = data.aws_region.current.name
      SNS_TOPIC_ARN     = aws_sns_topic.textract_results.arn
      TEXTRACT_ROLE_ARN = aws_iam_role.textract_to_sns.arn
    }
  }
}

# Retrieve Textract Lambda
resource "aws_lambda_permission" "retrieve_textract_allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.retrieve_textract_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge.eventbridge_rule_arns.retrieve_textract
}

data "aws_s3_object" "retrieve_textract" {
  bucket = var.deploy_bucket_name
  key    = "lambda/retrieve_textract.zip"
}

module "retrieve_textract_lambda_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  namespace            = var.namespace
  runtime              = "python3.10"
  timeout              = 300
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.retrieve_textract.version_id
  lambda_zip           = "lambda/retrieve_textract.zip"
  policy_arn           = tolist([aws_iam_policy.lambda_policy.arn, aws_iam_policy.custom_permit_textract.arn])
  handler              = "app.lambda_handler"
  lambda_function_name = "${local.project_name}-retrieve-textract"
  role_name            = "${local.project_name}-retrieve-textract-role"
  inline_policy        = data.aws_iam_policy_document.lambda-assume-role-policy.json
  enable_dlq           = true

  env_vars = {
    variables = {
      NAMESPACE = var.namespace,
      REGION    = data.aws_region.current.name
    }
  }
}

# Push to OpenSearch Lambda
resource "aws_lambda_permission" "push_to_opensearch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.push_to_opensearch_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge.eventbridge_rule_arns.push_to_opensearch
}

data "aws_s3_object" "push_to_opensearch" {
  bucket = var.deploy_bucket_name
  key    = "lambda/push_to_opensearch.zip"
}

module "push_to_opensearch_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  namespace            = var.namespace
  runtime              = "python3.10"
  timeout              = 300
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.push_to_opensearch.version_id
  lambda_zip           = "lambda/push_to_opensearch.zip"
  policy_arn           = tolist([aws_iam_policy.lambda_policy.arn, aws_iam_policy.custom_permit_opensearch.arn, aws_iam_policy.custom_permit_to_documents.arn, aws_iam_policy.custom_permits_push_to_opensearch_lambda.arn])
  handler              = "func.handler"
  lambda_function_name = "${local.project_name}-push-to-opensearch"
  role_name            = "${local.project_name}-push-to-opensearch-role"
  inline_policy        = data.aws_iam_policy_document.lambda-assume-role-policy.json
  enable_dlq           = true
  vpc_subnet_ids       = values(module.tfm_aws_network.private_subnets)
  vpc_security_group_ids = [
    module.tfm_aws_network.custom_sg.permit-to-opensearch-sg.id
  ]

  env_vars = {
    variables = {
      NAMESPACE                  = var.namespace,
      REGION                     = data.aws_region.current.name
      AWS_STS_REGIONAL_ENDPOINTS = "regional"
      ALLOWED_ORIGIN             = local.env_frontend_host
      TARGET_ROLE                = aws_iam_role.doc_search_app_access.arn
      OPENSEARCH_COLLECTION      = trimprefix(aws_opensearchserverless_collection.opensearch.collection_endpoint, "https://")
      DYNAMODB_TABLE_ID          = module.tfm_aws_dynamodb.dynamodb_table_id,
      DYNAMODB_TABLE_ARN         = module.tfm_aws_dynamodb.dynamodb_table_arn,
    }
  }
}

# Enrichment lambda to clean up SQS events sent to bridge pipe
resource "aws_lambda_permission" "sqs_enrichment" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.sqs_enrichment_function.function_name
  principal     = "pipes.amazonaws.com"
  source_arn    = aws_pipes_pipe.sqs_to_eventbridge.arn
}

data "aws_s3_object" "sqs_enrichment" {
  bucket = var.deploy_bucket_name
  key    = "lambda/sqs_enrichment.zip"
}

module "sqs_enrichment_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  namespace            = var.namespace
  runtime              = "python3.10"
  timeout              = 300
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.sqs_enrichment.version_id
  lambda_zip           = "lambda/sqs_enrichment.zip"
  policy_arn           = tolist([aws_iam_policy.lambda_policy.arn])
  handler              = "func.handler"
  lambda_function_name = "${local.project_name}-sqs-enrichment"
  role_name            = "${local.project_name}-sqs-enrichment-role"
  inline_policy        = data.aws_iam_policy_document.lambda-assume-role-policy.json
  enable_dlq           = true

  env_vars = {
    variables = {
      NAMESPACE = var.namespace,
      REGION    = data.aws_region.current.name
    }
  }
}

# OpenSearch Doc retrieval lambda, retrieves docs from Opensearch for download
resource "aws_lambda_permission" "opensearch_document_download" {
  function_name = module.opensearch_document_download_lambda_function.function_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gateway_api.execution_arn}/*/*"
}

data "aws_s3_object" "opensearch_document_download" {
  bucket = var.deploy_bucket_name
  key    = "lambda/opensearch_document_download.zip"
}

module "opensearch_document_download_lambda_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  namespace            = var.namespace
  runtime              = "python3.10"
  timeout              = 300
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.opensearch_document_download.version_id
  lambda_zip           = data.aws_s3_object.opensearch_document_download.key
  policy_arn           = tolist([aws_iam_policy.lambda_policy.arn, aws_iam_policy.custom_permit_opensearch.arn, aws_iam_policy.custom_permits_opensearch_download_lambda.arn])
  handler              = "app.lambda_handler"
  lambda_function_name = "${local.project_name}-opensearch_document_download"
  role_name            = "${local.project_name}-opensearch_document_download-role"
  enable_dlq           = true
  inline_policy        = data.aws_iam_policy_document.lambda-assume-role-policy.json
  vpc_subnet_ids       = values(module.tfm_aws_network.private_subnets)
  vpc_security_group_ids = [
    module.tfm_aws_network.custom_sg.permit-to-opensearch-sg.id
  ]

  env_vars = {
    variables = {
      NAMESPACE                  = var.namespace,
      REGION                     = data.aws_region.current.name,
      ALLOWED_ORIGIN             = local.env_frontend_host,
      DOCUMENT_BUCKET            = aws_s3_bucket.documents.id,
      DYNAMODB_TABLE_ID          = module.tfm_aws_dynamodb.dynamodb_table_id,
      DYNAMODB_TABLE_ARN         = module.tfm_aws_dynamodb.dynamodb_table_arn,
      AWS_STS_REGIONAL_ENDPOINTS = "regional"
      TARGET_ROLE                = aws_iam_role.doc_search_app_access.arn
      OPENSEARCH_COLLECTION      = trimprefix(aws_opensearchserverless_collection.opensearch.collection_endpoint, "https://")
    }
  }
}

### SWAGGER-UI

resource "aws_lambda_permission" "swagger_ui__allow_api_gateway" {
  function_name = module.swagger_ui_function.function_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gateway_api.execution_arn}/*/*"
}

data "aws_s3_object" "swagger_ui_function" {
  bucket = var.deploy_bucket_name
  key    = "lambda/swagger-ui.zip"
}

module "swagger_ui_function" {
  source               = "git::https://github.com/cloud-investors/tfm_aws_lambda.git?ref=v1.0.1"
  namespace            = var.namespace
  runtime              = "nodejs16.x"
  timeout              = 300
  deploy_bucket_id     = var.deploy_bucket_name
  deploy_bucket_arn    = data.aws_s3_bucket.deploy_bucket.arn
  lambda_zip_version   = data.aws_s3_object.swagger_ui_function.version_id
  lambda_zip           = data.aws_s3_object.swagger_ui_function.key
  policy_arn           = tolist([aws_iam_policy.swagger_ui.arn])
  handler              = "app.handler"
  lambda_function_name = "${local.project_name}-swagger_ui"
  role_name            = "${local.project_name}-swagger_ui-role"
  enable_dlq           = true
  inline_policy        = data.aws_iam_policy_document.lambda-assume-role-policy.json

  env_vars = {
    variables = {
      NAMESPACE      = var.namespace,
      REGION         = data.aws_region.current.name,
      ALLOWED_ORIGIN = local.env_frontend_host,
    }
  }
}
