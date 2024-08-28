## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_endpoints"></a> [endpoints](#module\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | n/a |
| <a name="module_subnets"></a> [subnets](#module\_subnets) | hashicorp/subnets/cidr | 1.0.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.19.0 |

## Resources

| Name | Type |
|------|------|
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_ec2_transit_gateway_vpc_attachment.tgw_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route53_resolver_rule_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule_association) | resource |
| [aws_security_group.dynamic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ec2_transit_gateway.tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway) | data source |
| [aws_iam_policy_document.dynamodb_endpoint_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.generic_endpoint_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_endpoint_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_resolver_rules.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_resolver_rules) | data source |
| [aws_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_table) | data source |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc_endpoint_service.dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |
| [aws_vpc_ipam_pool.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_ipam_pool) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azs"></a> [azs](#input\_azs) | A list of availability zones in the region | `list(string)` | n/a | yes |
| <a name="input_cidr_length"></a> [cidr\_length](#input\_cidr\_length) | The CIDR length to request from IPAM | `number` | `24` | no |
| <a name="input_custom_sg"></a> [custom\_sg](#input\_custom\_sg) | A list of objects for creating SGs. Each object should have a name, and contain additional objects for each rule under egress and ingress. | `list(object({ name = string, egress = list(object({ to_port = number, protocol = string, from_port = number, self = bool, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })), ingress = list(object({ to_port = number, protocol = string, from_port = number, self = bool, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })) }))` | `[]` | no |
| <a name="input_default_sg"></a> [default\_sg](#input\_default\_sg) | An object which contains all the rules for the VPC default SG | `object({ egress = list(object({ to_port = number, protocol = string, from_port = number, self = bool, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })), ingress = list(object({ to_port = number, protocol = string, from_port = number, self = bool, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })) })` | <pre>{<br>  "egress": [],<br>  "ingress": []<br>}</pre> | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Unique namespace for all resources. Should be PR number or prod. This will be to help name resources | `string` | n/a | yes |
| <a name="input_private_inbound_acl_rules"></a> [private\_inbound\_acl\_rules](#input\_private\_inbound\_acl\_rules) | List of maps of ingress rules to set on the Private Network ACL | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_private_outbound_acl_rules"></a> [private\_outbound\_acl\_rules](#input\_private\_outbound\_acl\_rules) | List of maps of egress rules to set on the Private Network ACL | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The name of your project. This will be to help name resources | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Mapping of all subnet information | <pre>list(<br>    object({<br>      name     = string,<br>      new_bits = number<br>    })<br>  )</pre> | <pre>[<br>  {<br>    "name": "private-subnet-1",<br>    "new_bits": 2<br>  },<br>  {<br>    "name": "private-subnet-2",<br>    "new_bits": 2<br>  }<br>]</pre> | no |
| <a name="input_use_az_ids"></a> [use\_az\_ids](#input\_use\_az\_ids) | Whether to use availability zone ids | `bool` | `false` | no |
| <a name="input_use_transit_gateway"></a> [use\_transit\_gateway](#input\_use\_transit\_gateway) | Set to true to connect private subnets to transit gateway | `bool` | `false` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_custom_sg"></a> [custom\_sg](#output\_custom\_sg) | n/a |
| <a name="output_custom_sg_id_map"></a> [custom\_sg\_id\_map](#output\_custom\_sg\_id\_map) | n/a |
| <a name="output_default_sg"></a> [default\_sg](#output\_default\_sg) | n/a |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | n/a |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | n/a |
| <a name="output_vpc_outputs"></a> [vpc\_outputs](#output\_vpc\_outputs) | n/a |
| <a name="output_vpce_outputs"></a> [vpce\_outputs](#output\_vpce\_outputs) | n/a |
