include "root" {
  path = find_in_parent_folders()
}
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_parent_terragrunt_dir()}//_modules/aws/sg"
}

dependencies {
  paths = ["../../vpc"]
}

dependency "vpc" {
  config_path = "../../vpc"
}

inputs = {
  name            = "sgr-pangea-${local.env_vars.env}-db-backend"
  description     = "Security groups for Database Backend"
  vpc_id          = dependency.vpc.outputs.vpc_id
  use_name_prefix = false

  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_ipv6_cidr_blocks = []
  egress_rules            = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      rule        = "postgresql-tcp"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
    }
  ]
}
