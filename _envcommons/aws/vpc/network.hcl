terraform {
  source = "${local.base_source_url}"
}

locals {
  base_source_url = "git::git@github.com:HOCKNAS/iac-terraform-modules.git//aws-vpc"
}

inputs = {

}