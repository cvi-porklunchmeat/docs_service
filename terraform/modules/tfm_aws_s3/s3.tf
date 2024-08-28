locals {
  bucket_destroy      = var.namespace == "prod" || var.force_destroy == true ? true : false
  intelligent_tiering = var.intelligent_tiering == true ? "Enabled" : "Disabled"
}


resource "aws_s3_bucket" "this" {
  count = var.create_bucket ? 1 : 0

  bucket = var.bucket
  # hack when `null` value can't be used (eg, from terragrunt, https://github.com/gruntwork-io/terragrunt/pull/1367)
  #acl = var.acl != "null" ? var.acl : null

  tags          = var.tags
  force_destroy = local.bucket_destroy
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_enabled != false ? aws_kms_key.kms[0].arn : null
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "this" {
  count  = var.create_bucket && var.acl != "null" ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  acl    = var.acl

  # As of April 2023, AWS screwed access lists on buckets and this resource has to depend upon all others in the module to construct correctly
  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_server_side_encryption_configuration.this,
    aws_s3_bucket_versioning.this,
    aws_s3_bucket_public_access_block.this,
    aws_s3_bucket_policy.this,
    aws_s3_bucket_ownership_controls.this
  ]
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.create_bucket && var.attach_public_policy ? 1 : 0

  # Chain resources (s3_bucket -> s3_bucket_policy -> s3_bucket_public_access_block)
  # to prevent "A conflicting conditional operation is currently in progress against this resource."
  bucket = var.attach_policy ? aws_s3_bucket_policy.this[0].id : aws_s3_bucket.this[0].id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
  depends_on = [
    aws_s3_bucket.this[0], aws_s3_bucket_ownership_controls.this[0]
  ]
}

resource "aws_s3_bucket_policy" "this" {
  count = var.create_bucket && var.attach_policy ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.combined[0].json
  depends_on = [
    aws_s3_bucket.this[0], aws_s3_bucket_ownership_controls.this[0]
  ]
}

data "aws_iam_policy_document" "combined" {
  count = var.create_bucket && var.attach_policy ? 1 : 0

  source_policy_documents = compact([
    var.attach_policy ? var.policy : ""
  ])
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count  = var.create_bucket && var.set_object_owner ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    object_ownership = var.object_ownership
  }
  depends_on = [
    aws_s3_bucket.this[0]
  ]
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "this" {
  bucket = aws_s3_bucket.this[0].id
  name   = "${var.bucket}-intelligent-tiering-config"

  status = local.intelligent_tiering

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
}

