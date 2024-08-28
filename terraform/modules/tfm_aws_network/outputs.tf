output "vpc_outputs" {
  value = module.vpc
}

output "vpce_outputs" {
  value = module.endpoints
}

output "default_sg" {
  value = aws_default_security_group.default
}

output "custom_sg" {
  value = aws_security_group.dynamic
}

output "private_subnets" {
  value = zipmap(module.vpc.private_subnets_cidr_blocks, module.vpc.private_subnets)
}

output "public_subnets" {
  value = zipmap(module.vpc.public_subnets_cidr_blocks, module.vpc.public_subnets)
}
