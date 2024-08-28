terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.46.0"
      configuration_aliases = [aws.network]
    }

    logicmonitor = {
      source  = "logicmonitor/logicmonitor"
      version = "2.0.12"
    }
  }
}
