
resource "aws_iam_group" "iam" {
  count = var.create_iam_grp ? 1 : 0
  name  = "cloud-${var.bucket}-S3"
}


resource "aws_iam_group_policy" "iam" {
  count = var.create_iam_grp ? 1 : 0
  name  = "cloud-${var.bucket}-S3-Access"
  group = aws_iam_group.iam[0].name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = data.aws_iam_policy_document.combined_bucket_access.json
}

data "aws_iam_policy_document" "combined_bucket_access" {
  source_policy_documents = var.kms_enabled != false ? [data.aws_iam_policy_document.iam.json, data.aws_iam_policy_document.kms_bucket_access[0].json] : [data.aws_iam_policy_document.iam.json]
}

data "aws_iam_policy_document" "iam" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.this[0].arn,
      "${aws_s3_bucket.this[0].arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "kms_bucket_access" {
  count = var.kms_enabled != false ? 1 : 0
  statement {
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt"
    ]
    resources = [
      aws_kms_key.kms[0].arn
    ]
  }
}