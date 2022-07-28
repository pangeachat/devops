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
  paths = ["../../vpc", "../alb-backend"]
}

dependency "vpc" {
  config_path = "../../vpc"
}
dependency "alb_backend_sg" {
  config_path = "../alb-backend"
}

inputs = {
  name            = "sgr-pangea-${local.env_vars.env}-ecs-container"
  description     = "Security groups for ECS Container"
  vpc_id          = dependency.vpc.outputs.vpc_id
  use_name_prefix = false

  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_ipv6_cidr_blocks = []
  egress_rules            = ["all-all"]
  ingress_with_source_security_group_id = concat(
    [
      {
        rule                     = "all-all"
        source_security_group_id = dependency.alb_backend_sg.outputs.security_group_id
        description              = "Ingress from the ALB"
      }
    ],
  )
  ingress_with_self = [
    {
      rule        = "all-all"
      description = "Ingress from other containers in the same security group"
    }
  ]
}
