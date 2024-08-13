# resource "aws_route53_zone" "app" {
#   name          = local.fqdn
#   force_destroy = true
#   vpc {
#     vpc_id = module.tfm_aws_network.vpc_outputs.vpc_id
#   }
# }

# resource "aws_route53_record" "app" {
#   zone_id = aws_route53_zone.app.zone_id
#   name    = local.fqdn
#   type    = "A"
#   alias {
#     name                   = aws_lb.frontend.dns_name
#     zone_id                = aws_lb.frontend.zone_id
#     evaluate_target_health = true
#   }
# }

# Linking

# data "aws_vpc" "network" {
#   provider = aws.network

#   tags = {
#     Name        = "Network VPC"
#     Environment = "Network"
#   }
# }

# resource "aws_route53_vpc_association_authorization" "app" {
#   vpc_id  = data.aws_vpc.network.id
#   zone_id = aws_route53_zone.app.id
# }

# resource "aws_route53_zone_association" "app" {
#   provider = aws.network
#   vpc_id   = aws_route53_vpc_association_authorization.app.vpc_id
#   zone_id  = aws_route53_vpc_association_authorization.app.zone_id
# }
