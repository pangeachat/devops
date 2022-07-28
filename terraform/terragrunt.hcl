locals {
  env_vars   = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  aws_region = "us-east-1"

}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}


# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt                     = true
    bucket                      = "pangea-terraform-state"
    key                         = "${path_relative_to_include()}/terraform.tfstate"
    region                      = local.aws_region
    dynamodb_table              = "terraform_locks"
    encrypt                     = true
    skip_metadata_api_check     = true
    skip_credentials_validation = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = merge(
  local.env_vars.inputs,
)
