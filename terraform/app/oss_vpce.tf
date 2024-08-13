resource "aws_opensearchserverless_vpc_endpoint" "app" {
  name       = "${var.namespace}-opensearch"
  subnet_ids = values(module.tfm_aws_network.private_subnets)
  vpc_id     = module.tfm_aws_network.vpc_outputs.vpc_id
  security_group_ids = [
    module.tfm_aws_network.custom_sg.default-vpce-sg.id,
  ]
}
