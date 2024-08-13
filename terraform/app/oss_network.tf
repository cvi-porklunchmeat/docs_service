module "tfm_aws_network_os" {
  providers = {
    aws = aws.data
  }
  source              = "git::https://github.com/cloud-investors/tfm_aws_network.git?ref=v7.0.0"
  namespace           = var.namespace
  project_name        = var.json.project_name
  cidr_length         = var.json.app.network.opensearch.cidr_length
  azs                 = var.json.app.network.opensearch.azs
  vpc_endpoints       = var.json.app.network.opensearch.vpce
  subnets             = var.json.app.network.opensearch.subnets
  custom_sg           = var.json.app.network.opensearch.custom_security_groups
  use_transit_gateway = true
}
