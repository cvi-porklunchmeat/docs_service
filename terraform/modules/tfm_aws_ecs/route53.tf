resource "aws_route53_zone" "this" {
  #checkov:skip=CKV2_AWS_38:This is a private hosted zone, so no DNSSEC
  #checkov:skip=CKV2_AWS_39:DNS logging is only available on public hosted zones
  count         = var.service == true && var.app_lb == true ? 1 : 0
  name          = local.fqdn
  force_destroy = true
  vpc {
    vpc_id = var.vpc_id
  }

  # Prevent the deletion of associated VPCs after
  # the initial creation. See documentation on
  # aws_route53_zone_association for details
  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_record" "this" {
  count   = var.service == true && var.app_lb == true ? 1 : 0
  zone_id = aws_route53_zone.this[0].zone_id
  name    = local.fqdn
  type    = "A"
  alias {
    name                   = aws_lb.this[0].dns_name
    zone_id                = aws_lb.this[0].zone_id
    evaluate_target_health = true
  }
}

# Linking

data "aws_vpc" "network" {
  count    = var.service == true && var.app_lb == true ? 1 : 0
  provider = aws.network

  tags = {
    Name        = "Network VPC"
    Environment = "Network"
  }
}

resource "aws_route53_vpc_association_authorization" "this" {
  count   = var.service == true && var.app_lb == true ? 1 : 0
  vpc_id  = data.aws_vpc.network[0].id
  zone_id = aws_route53_zone.this[0].id
  lifecycle {
    ignore_changes = [vpc_id]
  }
}

resource "aws_route53_zone_association" "this" {
  count    = var.service == true && var.app_lb == true ? 1 : 0
  provider = aws.network
  vpc_id   = aws_route53_vpc_association_authorization.this[0].vpc_id
  zone_id  = aws_route53_vpc_association_authorization.this[0].zone_id
  lifecycle {
    ignore_changes = [vpc_id]
  }
}
