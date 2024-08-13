output "s3_bucket_id" {
  value       = module.s3_bucket.bucket_id
  description = "S3 bucket ID"
}

output "s3_bucket_arn" {
  value       = module.s3_bucket.bucket_arn
  description = "S3 bucket ARN"
}

output "kms_key_arn" {
  value       = module.s3_bucket.kms_key_arn
  description = "S3 bucket kms key arn"
}

output "kms_key_alias" {
  value       = module.s3_bucket.kms_key_alias
  description = "S3 bucket kms key alias"
}
