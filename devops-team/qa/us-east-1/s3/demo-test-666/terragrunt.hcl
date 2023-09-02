
include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommons/aws/s3/bucket.hcl"
}

locals {
    name = "demo-test-666"
}

inputs = {
    bucket = local.name
    force_destroy = true
}