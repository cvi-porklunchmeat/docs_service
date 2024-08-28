module "alb_access_log_bucket" {
  count            = var.service == true && var.app_lb == true ? 1 : 0
  source           = "git::https://github.com/cloud-investors/tfm_aws_s3.git?ref=1.0.5" #checkov:skip=CKV_TF_1:We trust internal module tags
  bucket           = "${local.short_name}-access-logs"
  namespace        = var.namespace
  force_destroy    = true
  kms_enabled      = false # https://repost.aws/knowledge-center/elb-troubleshoot-access-logs - Must use Amazon S3 managed keys
  acl              = "private"
  set_object_owner = true
  object_ownership = "BucketOwnerPreferred"
  attach_policy    = true
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowELBRootAccount",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${lookup(local.aws_access_log_accts, data.aws_region.current.name)}:root"
        },
        "Action" : "s3:PutObject",
        "Resource" : "arn:aws:s3:::${local.short_name}-access-logs/*"
      },
      {
        "Sid" : "AWSLogDeliveryWrite",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "delivery.logs.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "arn:aws:s3:::${local.short_name}-access-logs/*",
        "Condition" : {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control"
          }
        }
      },
      {
        "Sid" : "AWSLogDeliveryAclCheck",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "delivery.logs.amazonaws.com"
        },
        "Action" : "s3:GetBucketAcl",
        "Resource" : "arn:aws:s3:::${local.short_name}-access-logs"
      }
    ]
  })

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

resource "aws_lb" "this" {
  count = var.service == true && var.app_lb == true ? 1 : 0
  #checkov:skip=CKV_AWS_150:Due to automation, we do not enable deletion protection
  name                       = local.short_name
  internal                   = true
  load_balancer_type         = "application"
  desync_mitigation_mode     = "strictest"
  drop_invalid_header_fields = true
  preserve_host_header       = false
  enable_xff_client_port     = true
  enable_http2               = true
  idle_timeout               = 120
  xff_header_processing_mode = "append"
  enable_deletion_protection = local.namespace == "prod" ? true : false

  security_groups = [aws_security_group.this_alb[0].id]
  subnets         = var.subnet_ids

  access_logs {
    bucket  = module.alb_access_log_bucket[0].bucket_id
    prefix  = local.short_name
    enabled = true
  }

}

resource "aws_lb_target_group" "this" {
  for_each                      = var.service == true && var.app_lb == true ? local.container_definitions : {}
  name_prefix                   = var.namespace
  target_type                   = "ip"
  load_balancing_algorithm_type = "least_outstanding_requests"

  stickiness {
    cookie_duration = var.cookie_duration
    enabled         = true
    type            = "lb_cookie"
  }

  health_check {
    path     = each.value.lbhc_path
    port     = each.value.lbhc_port
    protocol = upper(each.value.lbhc_protocol)
  }

  port     = each.value.containerPort
  protocol = each.value.containerProtocol
  vpc_id   = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb_listener" "this_http" {
  count             = var.service == true && var.app_lb == true ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "this" {
  for_each          = var.service == true && var.app_lb == true ? local.container_definitions : {}
  load_balancer_arn = aws_lb.this[0].arn
  port              = each.value.lbPort
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  certificate_arn   = aws_acm_certificate.this[0].arn

  default_action {
    type             = "forward"
    target_group_arn = lookup(aws_lb_target_group.this, each.key).arn
  }
  depends_on = [
    aws_lb_target_group.this
  ]
}


