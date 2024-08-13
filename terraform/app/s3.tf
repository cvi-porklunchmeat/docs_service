locals {
  # Mapping of AWS account numbers used to s3:PutObject for ALB logs
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
  aws_access_log_accts = {
    us-east-1      = "127311923021",
    us-east-2      = "033677994240",
    us-west-1      = "027434742980",
    us-west-2      = "797873946194",
    af-south-1     = "098369216593",
    ap-east-1      = "754344448648",
    ap-southeast-3 = "589379963580",
    ap-south-1     = "718504428378",
    ap-northeast-3 = "383597477331",
    ap-northeast-2 = "600734575887",
    ap-southeast-1 = "114774131450",
    ap-southeast-2 = "783225319266",
    ap-northeast-1 = "582318560864",
    ca-central-1   = "985666609251",
    eu-central-1   = "054676820928",
    eu-west-1      = "156460612806",
    eu-west-2      = "652711504416",
    eu-south-1     = "635631232127",
    eu-west-3      = "009996457667",
    eu-north-1     = "897822967062",
    me-south-1     = "076674570225",
    sa-east-1      = "507241528517"
  }
}


# resource "aws_s3_bucket" "alb" {
#   bucket = "${local.project_name}-access-logs"
#   acl    = "private"

#   force_destroy = true

#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"
#       }
#     }
#   }

#   versioning {
#     enabled = true
#   }

#   lifecycle_rule {
#     prefix  = local.project_name
#     enabled = true

#     noncurrent_version_transition {
#       days          = 90
#       storage_class = "STANDARD_IA"
#     }

#     noncurrent_version_transition {
#       days          = 180
#       storage_class = "GLACIER"
#     }

#     noncurrent_version_expiration {
#       days = 365
#     }
#   }
#
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Sid" : "AllowELBRootAccount",
#         "Effect" : "Allow",
#         "Principal" : {
#           "AWS" : "arn:aws:iam::${lookup(local.aws_access_log_accts, data.aws_region.current.name)}:root"
#         },
#         "Action" : "s3:PutObject",
#         "Resource" : "arn:aws:s3:::${local.project_name}-access-logs/*"
#       },
#       {
#         "Sid" : "AWSLogDeliveryWrite",
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service" : "delivery.logs.amazonaws.com"
#         },
#         "Action" : "s3:PutObject",
#         "Resource" : "arn:aws:s3:::${local.project_name}-access-logs/*",
#         "Condition" : {
#           "StringEquals" : {
#             "s3:x-amz-acl" : "bucket-owner-full-control"
#           }
#         }
#       },
#       {
#         "Sid" : "AWSLogDeliveryAclCheck",
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service" : "delivery.logs.amazonaws.com"
#         },
#         "Action" : "s3:GetBucketAcl",
#         "Resource" : "arn:aws:s3:::${local.project_name}-access-logs"
#       }
#     ]
#   })

# }

# KMS key for deploy bucket retrieval
# data "aws_kms_key" "by_alias" {
#   key_id = "alias/${var.namespace}-omatic-lambda-deploybucket-s3kms"
# }

# resource "aws_s3_bucket" "frontend" {
#   bucket        = local.fqdn
#   force_destroy = true
#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"
#       }
#     }
#   }
# }

# resource "aws_s3_bucket_public_access_block" "example" {
#   bucket = aws_s3_bucket.frontend.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_policy" "frontend" {
#   bucket = aws_s3_bucket.frontend.id
#   policy = data.aws_iam_policy_document.frontend.json
# }

# data "aws_iam_policy_document" "frontend" {
#   statement {
#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }
#     sid = "PermitAccessFromVPCEOnly"

#     actions = [
#       "s3:GetObject"
#     ]

#     condition {
#       test     = "StringEquals"
#       variable = "aws:SourceVpce"
#       values   = [module.tfm_aws_network.vpce_outputs.s3_int.endpoints.s3_int.id]
#     }

#     resources = [
#       aws_s3_bucket.frontend.arn,
#       "${aws_s3_bucket.frontend.arn}/*",
#     ]
#   }
# }

resource "aws_s3_bucket" "documents" {
  bucket = "${local.project_name}-documents"
  acl    = "private"

  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    prefix  = local.project_name
    enabled = true

    noncurrent_version_transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days          = 180
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = 365
    }
  }

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowLambdaAccessToBucket",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : module.fetch_and_download_lambda_function.lambda_role_arn
        },
        "Action" : "s3:PutObject",
        "Resource" : "arn:aws:s3:::${local.project_name}-documents/*"
      },
    ]
  })

}

resource "aws_s3_bucket_cors_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_notification" "sqs_to_pipe" {
  bucket = aws_s3_bucket.documents.id

  queue {
    id            = "pdf-upload-event"
    queue_arn     = aws_sqs_queue.sqs_to_pipe.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".pdf"
  }

  queue {
    id            = "txt-upload-event"
    queue_arn     = aws_sqs_queue.sqs_to_pipe.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".txt"
  }

  depends_on = [aws_sqs_queue_policy.sqs_to_pipe]
}
