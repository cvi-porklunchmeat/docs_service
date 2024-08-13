# Create the role that's assumed
resource "aws_iam_role" "doc_search_app_access" {
  provider           = aws.data
  name               = "${var.namespace}-doc_search_app_access"
  description        = "Role for doc-search application to access OpenSearch"
  assume_role_policy = data.aws_iam_policy_document.doc_search_app_assume.json
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "doc_search_app_access" {
  provider   = aws.data
  role       = aws_iam_role.doc_search_app_access.name
  policy_arn = aws_iam_policy.doc_search_app_access.arn
}

# Create the policy document that allows access to OpenSearch
resource "aws_iam_policy" "doc_search_app_access" {
  provider    = aws.data
  name_prefix = "${var.namespace}-custom-"
  policy      = data.aws_iam_policy_document.doc_search_app_access.json
}

# Build the policy document to be rendered
data "aws_iam_policy_document" "doc_search_app_access" {
  provider = aws.data
  statement {
    sid = "PermitOpenSearchAPI"

    actions = [
      "aoss:*",
      "es:*"
    ]

    resources = [
      aws_opensearchserverless_collection.opensearch.arn
    ]
  }
}

# Policy that allows other accounts/resources to assume this role
data "aws_iam_policy_document" "doc_search_app_assume" {
  provider = aws.data
  statement {

    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values = [
        module.push_to_opensearch_function.lambda_role_arn,
        module.opensearch_document_download_lambda_function.lambda_role_arn
      ]
    }
  }
}
