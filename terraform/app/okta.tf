locals {
  env_callback       = "${local.env_frontend_host}${local.env_callback_route}"
  dev_callback       = "http://localhost:3000${local.env_callback_route}"
  env_frontend_host  = "https://${local.fqdn}"
  env_callback_route = "/api/auth/callback/okta"
  redirect_uris      = var.namespace == "prod" ? [local.env_callback] : [local.env_callback, local.dev_callback]
}

# Create an app in okta for docs_service
resource "okta_app_oauth" "app" {
  label          = "${var.namespace}-${var.json.frontend.name}"
  type           = "web"
  response_types = ["code"]
  grant_types    = ["authorization_code", "refresh_token"]
  redirect_uris  = local.redirect_uris
  skip_groups    = true
  skip_users     = true
}

# Lookup the Okta groups that we want to assign to docs_service
data "okta_group" "techops" {
  name = var.namespace == "prod" ? "AWS TechOps Team" : "AWS TechOps Team"
}

data "okta_group" "appdev" {
  name = var.namespace == "prod" ? "AWS App Team" : "AWS App Team"
}

data "okta_group" "users" {
  name = var.namespace == "prod" ? "doc_service_prod" : "doc_service_uat"
}

# Assign these Okta groups to the Okta app for docs_service
resource "okta_app_group_assignment" "appdev" {
  app_id   = okta_app_oauth.app.id
  group_id = data.okta_group.appdev.id
}

resource "okta_app_group_assignment" "techops" {
  app_id   = okta_app_oauth.app.id
  group_id = data.okta_group.techops.id
}

resource "okta_app_group_assignment" "users" {
  app_id   = okta_app_oauth.app.id
  group_id = data.okta_group.users.id
}
