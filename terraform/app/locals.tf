locals {
  stage_name       = "v1"
  short_name       = var.json.short_name
  name             = "${lower(var.namespace)}-${lower(var.reponame)}"
  s3_path          = [""]
  project_name     = "${var.namespace}-${var.json.project_name}"
  fqdn             = var.namespace == "prod" ? var.json.frontend.fqdn : "${var.namespace}-${var.json.frontend.fqdn}"
  api_login_uri    = "https://${var.json.frontend.fqdn}/auth/authorize"
  api_redirect_uri = var.namespace == "prod" ? ["https://${var.json.frontend.fqdn}/api/auth/callback/azure-ad"] : ["https://${var.namespace}-${var.json.frontend.fqdn}/api/auth/callback/azure-ad", "http://localhost:8080/api/auth/callback/azure-ad"]
}
