data "azuread_client_config" "this" {}

resource "random_uuid" "admin" {}
resource "random_uuid" "read" {}

resource "random_uuid" "api_write_scope_id" {}
resource "random_uuid" "api_read_scope_id" {}
resource "random_uuid" "api_admin_app_role_id" {}
resource "random_uuid" "api_reader_app_role_id" {}

####
# AAD App - API
####
resource "azuread_application" "api" {
  display_name            = local.name
  logo_image              = filebase64("${path.module}/logo/ab.png")
  owners                  = [data.azuread_client_config.this.object_id]
  prevent_duplicate_names = false
  sign_in_audience        = "AzureADMyOrg"
  identifier_uris         = ["api://${local.name}-api"]

  feature_tags {
    enterprise = true
    hide       = true
  }

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access the commit methods"
      admin_consent_display_name = "api.write"
      enabled                    = true
      id                         = random_uuid.api_write_scope_id.result
      type                       = "Admin"
      user_consent_description   = "Allow the application to access the commit methods"
      user_consent_display_name  = "api.write"
      value                      = "api.write"
    }

    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access the read methods"
      admin_consent_display_name = "api.read"
      enabled                    = true
      id                         = random_uuid.api_read_scope_id.result
      type                       = "User"
      user_consent_description   = "Allow the application to access the read methods"
      user_consent_display_name  = "api.read"
      value                      = "api.read"
    }
  }

  app_role {
    allowed_member_types = ["User", "Application"]
    description          = "Read and Write"
    display_name         = "Admin"
    enabled              = true
    id                   = random_uuid.api_admin_app_role_id.result
    value                = "Admin"
  }

  app_role {
    allowed_member_types = ["User", "Application"]
    description          = "Read Only"
    display_name         = "Reader"
    enabled              = true
    id                   = random_uuid.api_reader_app_role_id.result
    value                = "Reader"
  }
}


resource "azuread_service_principal" "this" {
  client_id                    = azuread_application.api.client_id
  app_role_assignment_required = true
  owners                       = [data.azuread_client_config.this.object_id]
}

# AAD Group Selection
data "azuread_group" "appdev" {
  display_name     = "GitHub - cloud_AppDev_Team"
  security_enabled = true
}

data "azuread_group" "techops" {
  display_name     = "GitHub - cloud_TechOps_Team"
  security_enabled = true
}

data "azuread_group" "data" {
  display_name     = "GitHub - cloud_Data_Team"
  security_enabled = true
}

data "azuread_group" "users" {
  display_name     = "doc_service_prod"
  security_enabled = true
}

# Assign AAD Groups to API roles
resource "azuread_app_role_assignment" "appdev" {
  app_role_id         = azuread_application.api.app_role_ids["Admin"]
  principal_object_id = data.azuread_group.appdev.object_id
  resource_object_id  = azuread_service_principal.this.object_id
}

resource "azuread_app_role_assignment" "techops" {
  app_role_id         = azuread_application.api.app_role_ids["Admin"]
  principal_object_id = data.azuread_group.techops.object_id
  resource_object_id  = azuread_service_principal.this.object_id
}

resource "azuread_app_role_assignment" "data" {
  app_role_id         = azuread_application.api.app_role_ids["Admin"]
  principal_object_id = data.azuread_group.data.object_id
  resource_object_id  = azuread_service_principal.this.object_id
}

resource "azuread_app_role_assignment" "users" {
  app_role_id         = azuread_application.api.app_role_ids["Reader"]
  principal_object_id = data.azuread_group.users.object_id
  resource_object_id  = azuread_service_principal.this.object_id
}

####
# AAD App - Frontend
####

resource "azuread_application" "application" {

  display_name    = "${local.name}-app"
  identifier_uris = ["api://${local.name}-app"]
  owners          = [data.azuread_client_config.this.object_id]

  api {
    requested_access_token_version = 2
  }

  feature_tags {
    enterprise = true
    hide       = var.namespace == "prod" ? false : true
  }

  web {
    redirect_uris = local.api_redirect_uri
    homepage_url  = local.api_login_uri
    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = false
    }
  }

  required_resource_access {
    resource_app_id = azuread_application.api.client_id

    resource_access {
      id   = azuread_application.api.oauth2_permission_scope_ids["api.read"]
      type = "Scope"
    }
  }
}

resource "azuread_application_password" "application" {
  application_id = azuread_application.application.id
  display_name   = "Terraform Managed Password"
  end_date       = "2099-01-01T01:02:03Z"
}

resource "azuread_service_principal" "application" {
  client_id                    = azuread_application.application.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.this.object_id]
}

resource "azuread_application_pre_authorized" "frontend_spa_preauthorized" {
  application_id       = azuread_application.api.id
  authorized_client_id = azuread_application.application.client_id

  permission_ids = [
    random_uuid.api_read_scope_id.result,
    random_uuid.api_write_scope_id.result
  ]
}
