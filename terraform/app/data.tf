data "aws_region" "current" {
}

data "aws_ecr_authorization_token" "token" {

}

data "aws_caller_identity" "current" {
}

data "aws_caller_identity" "data" {
  provider = aws.data
}

data "aws_secretsmanager_secret" "okta" {
  arn = "arn:aws:secretsmanager:us-east-1:637288593987:secret:apps/prod/IA/okta-hWLu4k"
}

data "aws_secretsmanager_secret_version" "okta" {
  secret_id = data.aws_secretsmanager_secret.okta.id
}

data "aws_kms_key" "okta" {
  key_id = "arn:aws:kms:us-east-1:637288593987:key/83572b8d-9641-426a-b8b4-d2bc6ee6bbbc"
}

data "template_file" "openapi" {
  template = file("${path.module}/openapi.yaml")

  vars = {
    local_document_upload_lambda_function        = module.local_document_upload_lambda_function.invoke_arn
    swagger_ui_lambda_function                   = module.swagger_ui_function.invoke_arn
    fetch_and_download_lambda_function           = module.fetch_and_download_lambda_function.invoke_arn
    generate_document_url_lambda_function        = module.generate_document_url_lambda_function.invoke_arn
    opensearch_document_download_lambda_function = module.opensearch_document_download_lambda_function.invoke_arn
    authorizer_lambda_function                   = module.authorizer_lambda_function.invoke_arn
    authorizer_lambda_function_role              = aws_iam_role.authorizer_lambda.arn
    auth_token_lambda_function                   = module.auth_token_lambda_function.invoke_arn
    auth_authorize_lambda_function               = module.auth_authorize_lambda_function.invoke_arn
    allowed_origin                               = local.env_frontend_host
    namespace                                    = var.namespace
    region                                       = data.aws_region.current.name
    portal_name                                  = local.project_name
  }
}
