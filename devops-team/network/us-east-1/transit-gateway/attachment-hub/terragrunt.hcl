
include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommons/aws/transit-gateway/attachment.hcl"
}

dependencies {
  paths = ["../../vpc/network-1"]
}

dependency "vpc_network" {
  config_path = "../../vpc/network-1"
}

locals {
  name         = "attachment-hub"
  service_vars = read_terragrunt_config(find_in_parent_folders("service.hcl"))
  tags         = merge(local.service_vars.locals.tags, { name = local.name })
}

inputs = {

  name            = local.name
  description     = "TGW HUB"
  amazon_side_asn = 64532

  create_tgw = true
  share_tgw  = true

  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  enable_auto_accept_shared_attachments  = true

  vpc_attachments = {
    vpc_network = {
      vpc_id       = dependency.vpc_network.outputs.vpc_id
      subnet_ids   = dependency.vpc_network.outputs.private_subnet_ids_one_per_az
      dns_support  = true
      ipv6_support = false

      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false

      tgw_routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
        }
      ]
    }
  }

  ram_allow_external_principals = true
  ram_principals                = [408364916062, 488705786812, 535946792325, 779345935191]

  tags = local.tags
}