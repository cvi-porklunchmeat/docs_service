output "bucket_arn" {
  value       = aws_s3_bucket.this[0].arn
  description = "The Amazon Resource Name (ARN) identifying the bucket"
}

output "bucket_id" {
  value       = aws_s3_bucket.this[0].id
  description = "The ID identifying the bucket"
}

output "kms_key_arn" {
  value       = var.kms_enabled != false ? aws_kms_key.kms[0].arn : ""
  description = "The Amazon Resource Name (ARN) identifying the KMS key"
}

output "kms_key_alias" {
  value       = var.kms_enabled != false ? aws_kms_alias.kms[0].name : ""
  description = "The alias for the KMS key"
}

output "iam_grp_arn" {
  value       = var.create_iam_grp ? aws_iam_group.iam[0].arn : ""
  description = "The arn for the group"
}

output "iam_grp_name" {
  value       = var.create_iam_grp ? aws_iam_group.iam[0].name : ""
  description = "The name for the iam group"
}
