include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/rds/aws?version=5.0.1"
}
dependencies {
  paths = ["../../network/vpc", "../../network/sg/db-backend"]
}

dependency "vpc" {
  config_path = "../../network/vpc"
}
dependency "sg" {
  config_path = "../../network/sg/db-backend"
}


inputs = {

  identifier            = "pangea-${local.env_vars.env}-backend"
  use_identifier_prefix = false
  engine                = "postgres"
  engine_version        = "14.3"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20

  db_name                = "pangea_${local.env_vars.env}_backend"
  username               = "pangea_${local.env_vars.env}_admin"
  port                   = "5432"
  password               = "" #redacted
  create_random_password = false

  vpc_security_group_ids = [dependency.sg.outputs.security_group_id]

  maintenance_window = "Sun:07:00-Sun:10:00"
  backup_window      = "03:00-06:00"
  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = dependency.vpc.outputs.private_subnets

  # DB parameter group
  family = "postgres14"

  # DB option group
  major_engine_version            = "14"
  allocated_storage               = 20
  backup_retention_period         = 1
  db_subnet_group_use_name_prefix = false
  parameter_group_use_name_prefix = false
}
