locals {
  fqdn          = var.service == true && var.app_lb == true && lower(var.namespace) == "prod" ? var.app_fqdn : "${var.namespace}-${var.app_fqdn}"
  cloud_acm_arn = "arn:aws:acm-pca:us-east-1:637288593987:certificate-authority/84dff0f8-2273-4b71-9372-5b9a4e37d7f4"
}

resource "aws_acm_certificate" "this" {
  count                     = var.service == true && var.app_lb == true ? 1 : 0
  domain_name               = local.fqdn
  certificate_authority_arn = local.cloud_acm_arn
  subject_alternative_names = var.app_sans

  lifecycle {
    create_before_destroy = true
  }
}
