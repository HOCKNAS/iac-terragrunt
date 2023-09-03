
include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommons/aws/eks/cluster.hcl"
}

generate "provider-kubernetes" {
  path      = "provider-kubernetes.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

    provider "kubernetes" {
      alias                  = "provider-kubernetes"
      host                   = output.cluster_endpoint
      cluster_ca_certificate = base64decode(output.cluster_certificate_authority_data)
      token                  = data.aws_eks_cluster_auth.current.token
    }
    
EOF
}

dependencies {
  paths = ["../../vpc/network-1"]
}

dependency "vpc_dev" {
  config_path = "../../vpc/network-1"
}

locals {
  name         = "eks-dev-1"
  service_vars = read_terragrunt_config(find_in_parent_folders("service.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.aws_account_id
  tags         = merge(local.service_vars.locals.tags, { name = local.name })
}

inputs = {

  cluster_name                   = local.name
  cluster_version                = "1.27"
  cluster_endpoint_public_access = true

  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
    coredns = {
      configuration_values = jsonencode({
        computeType = "Fargate"
        # Ensure that we fully utilize the minimum amount of resources that are supplied by
        # Fargate https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
        # Fargate adds 256 MB to each pod's memory reservation for the required Kubernetes
        # components (kubelet, kube-proxy, and containerd). Fargate rounds up to the following
        # compute configuration that most closely matches the sum of vCPU and memory requests in
        # order to ensure pods always have the resources that they need to run.
        resources = {
          limits = {
            cpu = "0.25"
            # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
          requests = {
            cpu = "0.25"
            # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
        }
      })
    }
  }

  vpc_id     = dependency.vpc_dev.outputs.vpc_id
  subnet_ids = dependency.vpc_dev.outputs.private_subnets

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    # We need to add in the Karpenter node IAM role for nodes launched by Karpenter
    {
      rolearn  = "arn:aws:iam::${local.account_id}:instance-profile/${local.name}-karpenter"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
  ]

  eks_managed_node_groups = {
    non-fargate = {
      min_size     = 1
      max_size     = 5
      desired_size = 3

      instance_types = ["t3a.medium"]
      capacity_type  = "ON_DEMAND"

      update_config = {
        max_unavailable_percentage = 33
      }
    }
    non-fargate-spot = {
      min_size     = 1
      max_size     = 5
      desired_size = 2

      instance_types = ["t3a.large"]
      capacity_type  = "SPOT"

      update_config = {
        max_unavailable_percentage = 33
      }

    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  fargate_profiles = {
    karpenter = {
      selectors = [
        { namespace = "karpenter" }
      ]
    }
    kube-system = {
      selectors = [
        { namespace = "kube-system" }
      ]
    }
  }

  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.name
  })
}