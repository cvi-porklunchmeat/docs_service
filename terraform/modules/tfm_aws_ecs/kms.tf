resource "aws_kms_key" "this" {
  enable_key_rotation = true
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "${local.short_name}-ecs-pol",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        "Action" : "kms:*",
        "Resource" : "*",
      },
      {
        "Effect" : "Allow",
        "Principal" : { "Service" : "logs.${data.aws_region.current.name}.amazonaws.com" },
        "Action" : [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*",
        ],
        "Resource" : "*",
        "Condition" : {
          "ArnLike" : {
            "kms:EncryptionContext:aws:logs:arn" : "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        },
      },
    ],
  })

}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.short_name}-logs"
  target_key_id = aws_kms_key.this.key_id
}
