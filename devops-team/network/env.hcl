locals {
  environment = "network"
  owner_vars  = read_terragrunt_config(find_in_parent_folders("owner.hcl"))
  tags        = merge(local.owner_vars.locals.tags, { environment = local.environment })
}