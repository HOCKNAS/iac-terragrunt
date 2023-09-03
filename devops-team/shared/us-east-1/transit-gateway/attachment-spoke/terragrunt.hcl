
include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommons/aws/transit-gateway/attachment.hcl"
}

dependencies {
  paths = ["../../vpc/network-1", "../../../../network/us-east-1/transit-gateway/attachment-hub"]
}

dependency "vpc_shared" {
  config_path = "../../vpc/network-1"
}

dependency "attachment-hub" {
  config_path = "../../../../network/us-east-1/transit-gateway/attachment-hub"
}

locals {
  name         = "attachment-spoke"
  service_vars = read_terragrunt_config(find_in_parent_folders("service.hcl"))
  tags         = merge(local.service_vars.locals.tags, { name = local.name })
}

inputs = {

  name            = local.name
  description     = "TGW SPOKE"
  amazon_side_asn = 64532

  create_tgw = false
  share_tgw  = true

  ram_resource_share_arn = dependency.attachment-hub.outputs.ram_resource_share_id

  enable_auto_accept_shared_attachments  = true

  vpc_attachments = {
    vpc_shared = {

      tgw_id       = dependency.attachment-hub.outputs.ec2_transit_gateway_id

      vpc_id       = dependency.vpc_shared.outputs.vpc_id
      subnet_ids   = dependency.vpc_shared.outputs.private_subnet_ids_one_per_az
      dns_support  = true
      ipv6_support = false

      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false

    }
  }

  tags = local.tags
}