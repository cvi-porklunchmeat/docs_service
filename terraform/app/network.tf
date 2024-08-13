module "tfm_aws_network" {
  source              = "git::https://github.com/cloud-investors/tfm_aws_network.git?ref=v7.0.0"
  namespace           = var.namespace
  project_name        = var.json.project_name
  cidr_length         = var.json.app.network.app.cidr_length
  azs                 = var.json.app.network.app.azs
  vpc_endpoints       = var.json.app.network.app.vpce
  subnets             = var.json.app.network.app.subnets
  custom_sg           = var.json.app.network.app.custom_security_groups
  use_transit_gateway = true
}

# Get the VPC endpoint network interface IDs to target from ALB
data "aws_network_interface" "s3_vpce" {
  for_each = { for idx, subnet in var.json.app.network.app.subnets : idx => idx }
  id       = tolist(module.tfm_aws_network.vpce_outputs.s3_int.endpoints.s3_int.network_interface_ids)[each.key]
}
