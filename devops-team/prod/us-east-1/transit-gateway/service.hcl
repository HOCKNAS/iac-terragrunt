locals {
  service     = "transit-gateway"
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  tags        = merge(local.region_vars.locals.tags, { service = local.service })
}