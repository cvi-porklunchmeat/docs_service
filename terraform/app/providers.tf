provider "okta" {
  org_name  = "cloud"
  base_url  = "okta.com"
  api_token = jsondecode(data.aws_secretsmanager_secret_version.okta.secret_string)["OKTA_TOKEN"]
}

# AAD App provider
data "aws_secretsmanager_secret_version" "aad_graph_creds" {
  provider  = aws.management
  secret_id = var.az_secret_name
}
provider "azuread" {
  client_id     = jsondecode(data.aws_secretsmanager_secret_version.aad_graph_creds.secret_string)["client_id"]
  tenant_id     = jsondecode(data.aws_secretsmanager_secret_version.aad_graph_creds.secret_string)["tenant_id"]
  client_secret = jsondecode(data.aws_secretsmanager_secret_version.aad_graph_creds.secret_string)["client_secret"]
}

provider "aws" {
  region  = var.json.aws_region
  profile = "default"
  default_tags {
    tags = var.json.default_tags
  }
}

provider "aws" {
  region  = var.json.aws_region
  profile = "967336502278"
  alias   = "data"
  default_tags {
    tags = var.json.default_tags
  }
}

provider "aws" {
  alias   = "management"
  region  = var.json.aws_region
  profile = "00000000001"
  default_tags {
    tags = var.json.default_tags
  }
}

provider "aws" {
  region  = var.json.aws_region
  profile = "861337485143"
  alias   = "network"
  default_tags {
    tags = var.json.default_tags
  }
}

# Configure Docker
provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.token.proxy_endpoint
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}
