locals {
  aws_region = "us-east-1"
  env_vars   = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  tags       = merge(local.env_vars.locals.tags, { region = local.aws_region })
}