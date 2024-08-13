resource "random_id" "id" {
  byte_length = 6
}

resource "random_string" "next_secret" {
  length      = 64
  special     = true
  min_special = 8
  min_upper   = 8
  min_numeric = 8
  min_lower   = 8
}

### OKTA SECRET

resource "aws_secretsmanager_secret" "okta" {
  name       = "${local.project_name}-okta-${random_id.id.hex}"
  kms_key_id = aws_kms_key.okta.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "abacAllowUseOfTheSecret",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          ]
        },
        "Action" : "secretsmanager:GetSecretValue",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/access_project" : "$${aws:PrincipalTag/access_project}",
            "aws:ResourceTag/access_team" : "$${aws:PrincipalTag/access_team}",
            "aws:ResourceTag/cost_center" : "$${aws:PrincipalTag/cost_center}"
          }
        }
      }
    ]
  })
}

resource "aws_secretsmanager_secret_version" "okta" {
  secret_id = aws_secretsmanager_secret.okta.id
  secret_string = jsonencode({
    OKTA_ORG                  = "cloud"
    OKTA_ISSUER               = "https://cloud.okta.com"
    OKTA_CLIENT_ID            = okta_app_oauth.app.client_id
    OKTA_CLIENT_SECRET_REGION = data.aws_region.current.name
    OKTA_CLIENT_SECRET        = okta_app_oauth.app.client_secret
    OKTA_CLIENT_SCOPES        = "openid"
    OKTA_APP_NAME             = okta_app_oauth.app.id
    AZURE_AD_CLIENT_ID        = azuread_application.application.client_id
    AZURE_AD_CLIENT_SECRET    = azuread_application_password.application.value
    AZURE_AD_TENANT_ID        = data.azuread_client_config.this.tenant_id
    AZURE_AD_API_CLIENT_ID    = azuread_application.api.client_id
    NEXTAUTH_SECRET           = urlencode(random_string.next_secret.result)
    FRONTEND_CALLBACK_ROUTE   = local.env_callback_route
    FRONTEND_HOST             = local.env_frontend_host
    NEXTAUTH_URL              = local.env_frontend_host
    API_URL                   = aws_ssm_parameter.api_invoke_url.value
    # This is restricted to the abcloud.cloud domain so it's safe to expose
    NEXT_PUBLIC_ADOBE_API_KEY = "d85fbaa89009461fba745be7affb3150"
  })
}


resource "aws_ssm_parameter" "client_id" {
  name        = "${local.project_name}_client_id"
  description = "Okta app client ID (non-sensitive)"
  type        = "String"
  value       = okta_app_oauth.app.client_id
  overwrite   = "true"
}

resource "aws_ssm_parameter" "callback_uri" {
  name        = "${local.project_name}_callback_uri"
  description = "Okta app callback uri (non-sensitive)"
  type        = "String"
  value       = local.env_callback
  overwrite   = "true"
}
