
include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommons/aws/eks/karpenter.hcl"
}

dependencies {
  paths = ["../eks-dev-1"]
}

dependency "eks-dev-1" {
  config_path = "../eks-dev-1"
}

locals {
  name         = "eks-dev-1-karpenter"
  service_vars = read_terragrunt_config(find_in_parent_folders("service.hcl"))
  tags         = merge(local.service_vars.locals.tags, { name = local.name })
}

inputs = {

  iam_role_name            = local.name
  iam_role_use_name_prefix = false
  cluster_name             = dependency.eks-dev-1.outputs.cluster_name
  irsa_oidc_provider_arn   = dependency.eks-dev-1.outputs.oidc_provider_arn

  policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}