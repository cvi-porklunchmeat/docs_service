variable "project_name" {
  description = "The name of your project. This will be to help name resources"
  type        = string
}

variable "vpc_endpoints" {
  default = null
}

variable "custom_sg" {
  description = "A list of objects for creating SGs. Each object should have a name, and contain additional objects for each rule under egress and ingress."
  type        = list(object({ name = string, egress = list(object({ permit_vpc = bool, to_port = number, protocol = string, from_port = number, self = bool, prefix_list_name = string, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })), ingress = list(object({ permit_vpc = bool, to_port = number, protocol = string, from_port = number, self = bool, prefix_list_name = string, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })) }))
  default     = []
}

variable "default_sg" {
  description = "An object which contains all the rules for the VPC default SG"
  type        = object({ egress = list(object({ permit_vpc = bool, to_port = number, protocol = string, from_port = number, self = bool, prefix_list_name = string, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })), ingress = list(object({ permit_vpc = bool, to_port = number, protocol = string, from_port = number, self = bool, prefix_list_name = string, ipv6_cidr_blocks = list(string), cidr_blocks = list(string) })) })
  default = {
    egress           = [],
    ingress          = [],
    permit_vpc       = false,
    self             = null,
    prefix_list_name = null,
    ipv6_cidr_blocks = null
  }
}

variable "azs" {
  description = "A list of availability zones in the region"
  type        = list(string)
  default     = []
}

variable "cidr_length" {
  description = "The CIDR length to request from IPAM"
  type        = number
  default     = 24
}

variable "subnets" {
  description = "Mapping of all subnet information"
  type = list(
    object({
      name     = string,
      new_bits = number
    })
  )
  default = [{
    name     = "private-subnet-1"
    new_bits = 2
    },
    {
      name     = "private-subnet-2"
      new_bits = 2
  }]
}

variable "private_inbound_acl_rules" {
  description = "List of maps of ingress rules to set on the Private Network ACL"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "private_outbound_acl_rules" {
  description = "List of maps of egress rules to set on the Private Network ACL"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "namespace" {
  description = "Unique namespace for all resources. Should be PR number or prod. This will be to help name resources"
  type        = string
}

variable "use_transit_gateway" {
  description = "Set to true to connect private subnets to transit gateway"
  type        = bool
  default     = false
}
