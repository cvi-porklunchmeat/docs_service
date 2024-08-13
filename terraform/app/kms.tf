resource "aws_kms_key" "dynamodb_kms" {
  deletion_window_in_days = 7
  tags = {
    Name = "${local.project_name}-dynamodb"
  }
  description = "Key for dynamodb in env: ${local.project_name}"

  policy = data.aws_iam_policy_document.ddb_kms.json
}


data "aws_iam_policy_document" "ddb_kms" {
  statement {
    sid = "Allow access through Amazon DynamoDB for all principals in the account that are authorized to use Amazon DynamoDB"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values = [
        "${data.aws_caller_identity.current.account_id}",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "dynamodb.${data.aws_region.current.name}.amazonaws.com",
      ]
    }
  }

  statement {
    sid = "Terraform Pipeline AssumeRole Access"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"
      ]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "Backup Key Administrator Access"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::637288593987:role/AdministratorAccessRole",
      ]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "Allow direct access to key metadata to the account"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:Describe*",
      "kms:Get*",
      "kms:List*",
      "kms:RevokeGrant"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "Allow DynamoDB Service with service principal name dynamodb.amazonaws.com to describe the key directly"

    principals {
      type = "Service"
      identifiers = [
        "dynamodb.amazonaws.com"
      ]
    }

    actions = [
      "kms:Describe*",
      "kms:Get*",
      "kms:List*"
    ]

    resources = [
      "*"
    ]
  }

}

resource "aws_kms_alias" "dynamodb_kms" {
  name          = "alias/${local.project_name}-dynamodb"
  target_key_id = aws_kms_key.dynamodb_kms.id
}

resource "aws_kms_key" "okta" {
  description             = "${var.namespace}-okta-com-${random_id.id.hex}"
  deletion_window_in_days = 7
  policy                  = <<Policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Backup Key Administrator Access",
    "Effect": "Allow",
    "Principal": {
        "AWS": "arn:aws:iam::637288593987:role/AdministratorAccessRole"
    },
    "Action": "kms:*",
    "Resource": "*"
    }
  ]
}
Policy
}

####################### KMS key for ECR #######################
resource "aws_kms_key" "ecr" {
  description             = "ECR KMS Key for ${local.name}"
  deletion_window_in_days = var.namespace != "prod" ? 7 : 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${local.name}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
}
