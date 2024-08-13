# Terraform Client Environment config
terraform {
  backend "s3" {
    encrypt = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.2.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "default"
  default_tags {
    tags = var.json.default_tags
  }
}

