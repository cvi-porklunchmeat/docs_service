locals {
  acct_id = data.aws_caller_identity.current.account_id
}

module "endpoints" {
  source   = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  for_each = var.vpc_endpoints

  vpc_id             = module.vpc.vpc_id
  security_group_ids = contains(keys(each.value), "security_group") ? [aws_security_group.dynamic[each.value.security_group].id] : []
  subnet_ids         = [for az in local.availability_zone_subnets : az[0]]

  endpoints = {
    (each.key) = {
      route_table_ids     = each.key == "dynamodb" || each.key == "s3" ? module.vpc.private_route_table_ids : null
      policy              = each.key == "dynamodb" ? data.aws_iam_policy_document.dynamodb_endpoint_policy.json : (each.key == "s3" ? data.aws_iam_policy_document.s3_endpoint_policy.json : null)
      service             = each.value.service
      private_dns_enabled = each.key == "dynamodb" || each.key == "s3" ? null : each.value.private_dns_enabled
      service_type        = each.value.service_type
      tags                = each.value.tags
    }
  }
}

# Data source used to avoid race condition
data "aws_vpc_endpoint_service" "dynamodb" {
  service = "dynamodb"

  filter {
    name   = "service-type"
    values = ["Gateway"]
  }
}

data "aws_iam_policy_document" "s3_endpoint_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"

      values = [data.aws_vpc_endpoint_service.dynamodb.id]
    }
  }
}

data "aws_iam_policy_document" "generic_endpoint_policy" {
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

