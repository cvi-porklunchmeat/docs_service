resource "aws_kms_key" "kms" {
  #   for_each                = length(keys(var.server_side_encryption_configuration)) == 0 ? [] : [var.server_side_encryption_configuration]
  count                   = var.kms_enabled != false ? 1 : 0
  deletion_window_in_days = 7
  tags                    = merge({ "Name" = "${var.namespace}-s3key" }, var.tags)
  description             = "Key for SSE ${var.namespace}"
  policy                  = data.aws_iam_policy_document.kms_combined[0].json

  lifecycle {
    ignore_changes = [tags]
  }
  #   policy = <<Policy
  # {
  #   "Version": "2012-10-17",
  #   "Statement": [
  #     {
  #       "Sid": "Enable IAM User Permissions",
  #       "Effect": "Allow",
  #       "Principal": {
  #         "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  #       },
  #       "Action": "kms:*",
  #       "Resource": "*"
  #     },
  #     {
  #       "Sid": "Backup Key Administrator Access",
  #     "Effect": "Allow",
  #     "Principal": {
  #         "AWS": "arn:aws:iam::637288593987:role/AdministratorAccessRole"
  #     },
  #     "Action": "kms:*",
  #     "Resource": "*"
  #     }
  #   ]
  # }
  # Policy
}

# Fix is somewhere in here I think

data "aws_iam_policy_document" "kms" {
  statement {
    sid = "Enable IAM User Permissions"

    actions = [
      "kms:*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    resources = [
      "*",
    ]
  }

  statement {
    sid = "Backup Key Administrator Access"

    actions = [
      "kms:*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::637288593987:role/AdministratorAccessRole"]
    }

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "kms_combined" {
  count                   = var.kms_enabled != false ? 1 : 0
  source_policy_documents = var.key_iam_policy != null ? [data.aws_iam_policy_document.kms.json, var.key_iam_policy] : [data.aws_iam_policy_document.kms.json]
}



resource "aws_kms_alias" "kms" {
  count         = var.kms_enabled != false ? 1 : 0
  name          = "alias/${var.bucket}-s3kms"
  target_key_id = aws_kms_key.kms[0].id
}