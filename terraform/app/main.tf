# Terraform Client Environment config
terraform {
  backend "s3" {
    encrypt = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.37.0"
    }
    okta = {
      source  = "okta/okta"
      version = "3.41.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}
