
include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommons/aws/vpc/network.hcl"
}

locals {
  name         = "network-1"
  service_vars = read_terragrunt_config(find_in_parent_folders("service.hcl"))
  tags         = merge(local.service_vars.locals.tags, { name = local.name })
}

inputs = {

  name = local.name
  cidr = "172.20.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["172.20.1.0/24", "172.20.2.0/24", "172.20.3.0/24"]
  custom_private_route_table_routes = [
    {
      cidr_block         = "10.0.0.0/16"
      transit_gateway_id = "tgw-027cef61900537cfc"
    },
    {
      cidr_block         = "10.1.0.0/16"
      transit_gateway_id = "tgw-027cef61900537cfc"
    },
    {
      cidr_block         = "10.2.0.0/16"
      transit_gateway_id = "tgw-027cef61900537cfc"
    },
    {
      cidr_block         = "10.3.0.0/16"
      transit_gateway_id = "tgw-027cef61900537cfc"
    }
  ]

  public_subnets = ["172.20.101.0/24", "172.20.102.0/24", "172.20.103.0/24"]
  custom_public_route_table_routes = [
    {
      cidr_block         = "10.0.0.0/16"
      transit_gateway_id = "tgw-027cef61900537cfc"
    },
    {
      cidr_block         = "10.1.0.0/16"
      transit_gateway_id = "tgw-027cef61900537cfc"
    },
    {
      cidr_block         = "10.2.0.0/16"
      transit_gateway_id = "tgw-027cef61900537cfc"
    },
    {
      cidr_block         = "10.3.0.0/16"
      transit_gateway_id = "tgw-027cef61900537cfc"
    }
  ]
  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}