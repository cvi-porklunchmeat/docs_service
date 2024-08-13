# resource "aws_iam_policy" "frontend_lambda_policy" {
#   name        = "${local.project_name}-frontend-lambda-policy"
#   path        = "/"
#   description = "IAM policy for a lambda"
#   policy      = data.aws_iam_policy_document.frontend_lambda_policy_doc.json
# }

# data "aws_iam_policy_document" "frontend_lambda_policy_doc" {
#   statement {
#     actions = [
#       "s3:GetObject"
#     ]
#     resources = ["arn:aws:s3:::${local.fqdn}/index.html"]
#   }
# }

# resource "aws_iam_policy" "authorizer_lambda_policy" {
#   name        = "${local.project_name}-authorizer-lambda-policy"
#   path        = "/"
#   description = "IAM policy for authorizer lambda"
#   policy      = data.aws_iam_policy_document.authorizer_lambda_policy_doc.json
# }

# data "aws_iam_policy_document" "authorizer_lambda_policy_doc" {
#   statement {
#     actions = [
#       "lambda:InvokeFunction"
#     ]
#     resources = [module.oauth_authorize_lambda_function.arn, module.oauth_token_lambda_function.arn]
#     condition {
#       test     = "ArnLike"
#       variable = "aws:SourceArn"

#       values = [
#         aws_api_gateway_rest_api.gateway_api.arn
#       ]
#     }
#   }
# }

resource "aws_iam_policy" "lambda_policy" {
  name        = "${local.project_name}-lambda-policy"
  path        = "/"
  description = "IAM policy for a lambda"
  policy      = data.aws_iam_policy_document.lambda_policy_doc.json
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "sqs:*"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "apigateway:*"
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["iam:PassRole"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

# API Gateway logging role and policy
resource "aws_iam_role" "api_cloudwatch" {
  name = "${local.project_name}_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "api_cloudwatch" {
  name = "${local.project_name}_cloudwatch-api-role-policy"
  role = aws_iam_role.api_cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "authorizer_lambda" {
  name = "${var.namespace}-authorizer-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "apigateway.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "authorizer_lambda" {
  name = "${var.namespace}-authorizer_lambda-role-policy"
  role = aws_iam_role.authorizer_lambda.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "authorizer_lambda" {
  role       = aws_iam_role.authorizer_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

###

data "aws_iam_policy_document" "custom_assume_role" {
  statement {
    actions = ["sts:AssumeRole", ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "apigateway.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "custom_permits" {
  name_prefix = "${var.namespace}-custom-"
  policy      = data.aws_iam_policy_document.custom_permits.json
}

data "aws_iam_policy_document" "custom_permits" {
  statement {
    sid = "PermitToSecret"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.okta.arn
    ]
  }

  statement {
    sid = "PermitToKey"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = [
      aws_kms_key.okta.arn
    ]
  }
}

resource "aws_iam_policy" "custom_permits_fetch_download_lambda" {
  name_prefix = "${var.namespace}-fetch-"
  policy      = data.aws_iam_policy_document.custom_permits_fetch_download_lambda.json
}

data "aws_iam_policy_document" "custom_permits_fetch_download_lambda" {

  statement {
    sid = "PermitsToS3Bucket"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.documents.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "custom_permits_generate_document_url_lambda" {
  name_prefix = "${var.namespace}-generate-document-"
  policy      = data.aws_iam_policy_document.custom_permits_generate_document_url_lambda.json
}

data "aws_iam_policy_document" "custom_permits_generate_document_url_lambda" {

  statement {
    sid = "PermitsToS3Bucket"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.documents.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "custom_permits_local_upload_lambda" {
  name_prefix = "${var.namespace}-ds-local-"
  policy      = data.aws_iam_policy_document.custom_permits_local_upload_lambda.json
}

data "aws_iam_policy_document" "custom_permits_local_upload_lambda" {

  statement {
    sid = "PermitsDynamoDB"

    actions = [
      "dynamodb:PutItem",
    ]

    resources = [
      module.tfm_aws_dynamodb.dynamodb_table_arn
    ]
  }

  statement {
    sid = "PermitDynamoDbKMS"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]

    resources = [
      aws_kms_key.dynamodb_kms.arn
    ]
  }

  statement {
    sid = "PermitsToS3Bucket"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.documents.arn}/*"
    ]
  }
  statement {
    sid = "PermitsToDynamoDB"

    actions = [
      "dynamodb:GetShardIterator",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:ListStreams",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:ConditionCheckItem",
      "dynamodb:PutItem",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:UpdateItem"
    ]

    resources = [
      module.tfm_aws_dynamodb.dynamodb_table_arn
    ]
  }
}

# Permit access to textract

resource "aws_iam_policy" "custom_permit_textract" {
  name_prefix = "${var.namespace}-textract-"
  policy      = data.aws_iam_policy_document.custom_permit_textract.json
}

data "aws_iam_policy_document" "custom_permit_textract" {
  statement {
    sid = "PermitToTextract"

    actions = [
      "textract:GetDocumentTextDetection",
      "textract:StartDocumentTextDetection"
    ]

    resources = ["*"]
  }

  statement {
    sid = "PermitToS3"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = ["${aws_s3_bucket.documents.arn}/*"]
  }
}

# Role for Textract to assume and push results to SNS

resource "aws_iam_role" "textract_to_sns" {
  name = "${local.project_name}-textract-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "textract.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "textract_to_sns" {
  name   = "${local.project_name}-textract-role-policy"
  role   = aws_iam_role.textract_to_sns.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:*"
            ],
            "Resource": "${aws_sns_topic.textract_results.arn}"
        }
    ]
}
EOF
}

# Permit access to OpenSearch
resource "aws_iam_policy" "custom_permit_opensearch" {
  name_prefix = "${var.namespace}-opensearch-"
  policy      = data.aws_iam_policy_document.custom_permit_opensearch.json
}

data "aws_iam_policy_document" "custom_permit_opensearch" {
  statement {
    sid = "AllowAssumeRole"

    actions = [
      "sts:AssumeRole"
    ]

    resources = [
      aws_iam_role.doc_search_app_access.arn
    ]
  }
}

resource "aws_iam_policy" "custom_permit_to_documents" {
  name_prefix = "${var.namespace}-textract-"
  policy      = data.aws_iam_policy_document.custom_permit_to_documents.json
}

data "aws_iam_policy_document" "custom_permit_to_documents" {
  statement {
    sid = "PermitToS3"

    actions = [
      "s3:GetObject"
    ]

    resources = ["${aws_s3_bucket.documents.arn}/*"]
  }
}

# Custom permit access to dynamoDB for download lambda
resource "aws_iam_policy" "custom_permits_opensearch_download_lambda" {
  name_prefix = "${var.namespace}-ds-local-"
  policy      = data.aws_iam_policy_document.custom_permits_opensearch_download_lambda.json
}

data "aws_iam_policy_document" "custom_permits_opensearch_download_lambda" {

  statement {
    sid = "PermitsDynamoDB"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:ConditionCheckItem",
      "dynamodb:GetRecords",
      "dynamodb:DescribeTable"
    ]

    resources = [
      module.tfm_aws_dynamodb.dynamodb_table_arn
    ]
  }

  statement {
    sid = "PermitDynamoDbKMS"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]

    resources = [
      aws_kms_key.dynamodb_kms.arn
    ]
  }
}


# Custom permit access to dynamoDB for push to opensearch lambda
resource "aws_iam_policy" "custom_permits_push_to_opensearch_lambda" {
  name_prefix = "${var.namespace}-ds-local-"
  policy      = data.aws_iam_policy_document.custom_permits_push_to_opensearch_lambda.json
}

data "aws_iam_policy_document" "custom_permits_push_to_opensearch_lambda" {

  statement {
    sid = "PermitsDynamoDBLists"

    actions = [
      "dynamodb:List*",
      "dynamodb:DescribeReservedCapacity*",
      "dynamodb:DescribeLimits",
      "dynamodb:DescribeTimeToLive"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    sid = "PermitsDynamoDBOpenSearch"

    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:PutItem",
      "dynamodb:ListTables",
      "dynamodb:ListStreams",
      "dynamodb:Get*",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeStream",
      "dynamodb:ConditionCheckItem",
      "dynamodb:BatchWrite*",
      "dynamodb:BatchGet*"
    ]

    resources = [
      module.tfm_aws_dynamodb.dynamodb_table_arn
    ]
  }

  statement {
    sid = "PermitDynamoDbKMSOpenSearch"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]

    resources = [
      aws_kms_key.dynamodb_kms.arn
    ]
  }
}

resource "aws_iam_policy" "swagger_ui" {
  name        = "${local.project_name}-swagger_ui-lambda-policy"
  path        = "/"
  description = "IAM policy for a swagger_ui lambda"
  policy      = data.aws_iam_policy_document.swagger_ui.json
}

data "aws_iam_policy_document" "swagger_ui" {
  statement {
    actions = [
      "apigateway:GET",
      "apigateway:PUT",
      "apigateway:PATCH",
      "apigateway:POST",
      "apigateway:DELETE"
    ]
    resources = ["${aws_api_gateway_rest_api.gateway_api.arn}/*"]
  }
}
