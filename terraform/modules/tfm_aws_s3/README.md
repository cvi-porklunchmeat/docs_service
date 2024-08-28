# TFM_AWS_S3

- Terraform module for s3 buckets

# Example Terraform
```hcl

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket}",
    ]
  }
}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid = "${var.reponame} KMS policy"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "${module.lambda.role}"
      ]
    }
    resources = ["*"]
  }
}


module "s3_bucket" {
  source = "git::https://github.com/cloud-investors/tfm_aws_s3.git?ref=feature/initial"
  ## ref=0.1.12 will point at a specific release
  ## ref=feature_branch will point at a local branch - make sure it's pushed to the remote! 

  bucket        = var.bucket
  acl           = "private"
  ## force_destroy = true ## this is an override variable, only pass in if you need to allow the non-development bucket to have force_destroy set to true
  key_iam_policy = data.aws_iam_policy_document.kms_policy.json
  namespace     = var.namespace
  attach_policy = true
  policy        = data.aws_iam_policy_document.bucket_policy.json
  set_object_owner = true
  object_ownership = "BucketOwnerPreferred"
  intelligent_tiering = true # 90 day archive 

  tags = {
    Owner = "Bilbo"
  }

  kms_enabled = true

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```
