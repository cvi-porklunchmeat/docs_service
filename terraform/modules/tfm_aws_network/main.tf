locals {
  name                           = "${var.namespace}-${var.project_name}"
  azs                            = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, 1)
  network_acct_id                = "861337485143"
  private_subnet_route_table_ids = var.use_transit_gateway == true ? toset(module.vpc.private_route_table_ids) : []
  transit_gateway_ids = {
    us-east-1      = "tgw-030820dedc86de5a8",
    us-west-2      = "tgw-0fa41263b97d9405d",
    eu-west-1      = "tgw-061f6d49306c91b2c",
    eu-west-2      = "tgw-08e2defbbd1735193",
    ap-northeast-1 = "tgw-0526768f13b0336cf",
    ap-southeast-1 = "tgw-02a80e8010b651cff"
  }
  pl = { for pl in data.aws_ec2_managed_prefix_list.this : pl.name => {
    name           = pl.name
    id             = pl.id
    arn            = pl.arn
    address_family = pl.address_family
    max_entries    = pl.max_entries
    tags           = pl.tags
    entries        = pl.entries
    }
  }

  subnets = [for index, subnet in var.subnets : {
    "name" : "${var.namespace}-${data.aws_caller_identity.current.account_id}-${index}",
    "new_bits" : subnet.new_bits
    }
  ]

  availability_zone_subnets = {
    for s in data.aws_subnet.this : s.availability_zone => s.id...
  }
}

data "aws_availability_zones" "available" {
}

### Get the next available CIDR from IPAM

data "aws_vpc_ipam_pool" "this" {
  filter {
    name   = "ipam-region"
    values = ["us-east-1"]
  }

  filter {
    name   = "locale"
    values = [data.aws_region.current.name]
  }

  filter {
    name   = "description"
    values = ["${upper(data.aws_region.current.name)}*"]
  }

  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
}

### 
data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}


### Shared Org Route53 Ruless
data "aws_route53_resolver_rules" "this" {
  rule_type    = "FORWARD"
  share_status = "SHARED_WITH_ME"
  name_regex   = "prod-.*"
  owner_id     = local.network_acct_id
}

resource "aws_route53_resolver_rule_association" "this" {
  for_each         = data.aws_route53_resolver_rules.this.resolver_rule_ids
  resolver_rule_id = each.value
  vpc_id           = module.vpc.vpc_id
}

data "aws_ec2_managed_prefix_lists" "this" {
}

data "aws_ec2_managed_prefix_list" "this" {
  count = length(data.aws_ec2_managed_prefix_lists.this.ids)
  id    = tolist(data.aws_ec2_managed_prefix_lists.this.ids)[count.index]
}

resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = [for item in var.default_sg.ingress : {
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      prefix_list_name = item.prefix_list_name
      permit_vpc       = item.permit_vpc
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    }]
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      prefix_list_ids  = ingress.value.prefix_list_name != null ? [lookup(local.pl, ingress.value.prefix_list_name).id] : null
      cidr_blocks      = ingress.value.permit_vpc ? setunion(ingress.value.cidr_blocks, [module.vpc.vpc_cidr_block]) : ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      self             = ingress.value.self

    }
  }
  dynamic "egress" {
    for_each = [for item in var.default_sg.egress : {
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      permit_vpc       = item.permit_vpc
      prefix_list_name = item.prefix_list_name
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    }]
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      prefix_list_ids  = egress.value.prefix_list_name != null ? [lookup(local.pl, egress.value.prefix_list_name).id] : null
      cidr_blocks      = egress.value.permit_vpc ? setunion(egress.value.cidr_blocks, [module.vpc.vpc_cidr_block]) : egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      self             = egress.value.self
    }
  }
}

resource "aws_security_group" "dynamic" {
  for_each = {
    for sg in var.custom_sg : sg.name => sg
  }
  name   = "${var.namespace}-${each.value.name}"
  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = [for item in each.value.ingress : {
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      prefix_list_name = item.prefix_list_name
      permit_vpc       = item.permit_vpc
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    }]
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      prefix_list_ids  = ingress.value.prefix_list_name != null ? [lookup(local.pl, ingress.value.prefix_list_name).id] : null
      cidr_blocks      = ingress.value.permit_vpc ? setunion(ingress.value.cidr_blocks, [module.vpc.vpc_cidr_block]) : ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      self             = ingress.value.self

    }
  }
  dynamic "egress" {
    for_each = [for item in each.value.egress : {
      from_port        = item.from_port
      to_port          = item.to_port
      protocol         = item.protocol
      prefix_list_name = item.prefix_list_name
      permit_vpc       = item.permit_vpc
      cidr_blocks      = item.cidr_blocks
      ipv6_cidr_blocks = item.ipv6_cidr_blocks
      self             = item.self
    }]
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      prefix_list_ids  = egress.value.prefix_list_name != null ? [lookup(local.pl, egress.value.prefix_list_name).id] : null
      cidr_blocks      = egress.value.permit_vpc ? setunion(egress.value.cidr_blocks, [module.vpc.vpc_cidr_block]) : egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      self             = egress.value.self
    }
  }
}

module "subnets" {
  source          = "hashicorp/subnets/cidr"
  version         = "1.0.0"
  base_cidr_block = module.vpc.vpc_cidr_block
  networks        = local.subnets
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = local.name

  use_ipam_pool       = true
  ipv4_ipam_pool_id   = data.aws_vpc_ipam_pool.this.id
  ipv4_netmask_length = var.cidr_length
  azs                 = local.azs

  private_subnet_names = keys(module.subnets.network_cidr_blocks)
  private_subnets      = values(module.subnets.network_cidr_blocks)

  private_dedicated_network_acl = true
  private_outbound_acl_rules    = var.private_outbound_acl_rules
  private_inbound_acl_rules     = var.private_inbound_acl_rules

  create_database_subnet_group  = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = false
  single_nat_gateway = false
  enable_vpn_gateway = false

  enable_dhcp_options = false

  enable_flow_log           = true
  flow_log_destination_type = "s3"
  flow_log_destination_arn  = "arn:aws:s3:::cloud-global-vpc-flow-logs"
}

data "aws_subnet" "this" {
  for_each = { for subnet in local.subnets : subnet.name => subnet if var.use_transit_gateway == true }
  vpc_id   = module.vpc.vpc_id
  filter {
    name   = "tag:Name"
    values = [each.key]
  }
  depends_on = [module.vpc, module.subnets]
}

data "aws_route_table" "this" {
  for_each  = { for subnet in local.subnets : subnet.name => subnet if var.use_transit_gateway == true }
  vpc_id    = module.vpc.vpc_id
  subnet_id = data.aws_subnet.this[each.key].id
}

resource "aws_route" "this" {
  for_each               = data.aws_route_table.this
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = data.aws_ec2_transit_gateway.tgw[0].id
}

# Subnet route table associations
resource "aws_route_table_association" "this" {
  for_each       = { for subnet in local.subnets : subnet.name => subnet }
  subnet_id      = data.aws_subnet.this[each.key].id
  route_table_id = data.aws_route_table.this[each.key].id
}

# Transit Gateway

data "aws_ec2_transit_gateway" "tgw" {
  count = var.use_transit_gateway == true ? 1 : 0
  id    = lookup(local.transit_gateway_ids, data.aws_region.current.name)
}

data "aws_ec2_transit_gateway_attachment" "inspection" {
  count    = var.use_transit_gateway == true ? 1 : 0
  provider = aws.network
  filter {
    name   = "tag:Name"
    values = ["Inspection VPC TGW Attachment"]
  }
}

data "aws_ec2_transit_gateway_route_table" "legacy" {
  count    = var.use_transit_gateway == true ? 1 : 0
  provider = aws.network
  filter {
    name   = "tag:Name"
    values = ["Default - Legacy"]
  }
}

data "aws_ec2_transit_gateway_route_table" "inspection" {
  count    = var.use_transit_gateway == true ? 1 : 0
  provider = aws.network
  filter {
    name   = "tag:Name"
    values = ["Inspection [INGRESS]"]
  }
}

data "aws_ec2_transit_gateway_route_table" "firewall" {
  count    = var.use_transit_gateway == true ? 1 : 0
  provider = aws.network
  filter {
    name   = "tag:Name"
    values = ["Firewall [EGRESS]"]
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach" {
  count              = var.use_transit_gateway == true ? 1 : 0
  subnet_ids         = [for az in local.availability_zone_subnets : az[0]]
  transit_gateway_id = data.aws_ec2_transit_gateway.tgw[0].id
  vpc_id             = module.vpc.vpc_id
}

# Transit Gateway - Inspection Logic

# Associate the VPC CIDR to the TGW inspection route table (so all VPC traffic goes to the FW)
resource "aws_ec2_transit_gateway_route_table_association" "inspection" {
  count                          = var.use_transit_gateway == true ? 1 : 0
  provider                       = aws.network
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attach[0].id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.inspection[0].id # inspection
  replace_existing_association   = true
}

# Propagate the VPC CIDR to the TGW firewall route table (so traffic leaving the FW knows where to go)
resource "aws_ec2_transit_gateway_route_table_propagation" "firewall" {
  count                          = var.use_transit_gateway == true ? 1 : 0
  provider                       = aws.network
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attach[0].id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.firewall[0].id # fw
}

# The legacy TGW route table is configured for default propagation, so we need to remove our new VPC CIDR from it
# Else, traffic flow will be asyncronous (and the firewall will drop it)
resource "terraform_data" "remove_default_propagation" {
  count = var.use_transit_gateway == true ? 1 : 0
  triggers_replace = [
    aws_ec2_transit_gateway_vpc_attachment.tgw_attach[0].id
  ]
  provisioner "local-exec" {
    command = "aws ec2 disable-transit-gateway-route-table-propagation --region ${data.aws_region.current.name} --profile AWS_TechOps_Team_Network-861337485143 --transit-gateway-route-table-id ${data.aws_ec2_transit_gateway_route_table.legacy[0].id} --transit-gateway-attachment-id ${aws_ec2_transit_gateway_vpc_attachment.tgw_attach[0].id}"
  }
}

# Create route for this new VPC CIDR in the Legacy TGW route table, that points to the inspection VPC attachment (send to firewall)
resource "aws_ec2_transit_gateway_route" "legacy" {
  count                          = var.use_transit_gateway == true ? 1 : 0
  provider                       = aws.network
  destination_cidr_block         = module.vpc.vpc_cidr_block
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_attachment.inspection[0].id # should be fw attachment
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.legacy[0].id    # default
  depends_on                     = [terraform_data.remove_default_propagation]
}
