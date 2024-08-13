module "s3_bucket" {
  source = "git::https://github.com/cloud-investors/tfm_aws_s3.git?ref=1.0.5"
  ## ref=0.1.12 will point at a specific release
  ## ref=feature_branch will point at a local branch - make sure it's pushed to the remote! 

  bucket    = var.bucketname
  namespace = var.namespace
  tags      = var.tags
  acl       = "null"

  force_destroy = true
  kms_enabled   = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
    }
  }

}
