include "root" {
  path = find_in_parent_folders()
}
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_parent_terragrunt_dir()}//_modules/aws/ecs-service"
}

dependencies {
  paths = ["../../network/vpc", "../../network/ecs-cluster/backend", "../../network/elb/backend", "../../network/sg/ecs-container"]
}

dependency "vpc" {
  config_path = "../../network/vpc"
}
dependency "ecs_cluster" {
  config_path = "../../network/ecs-cluster/backend"
}
dependency "alb" {
  config_path = "../../network/elb/backend"
}
dependency "sg" {
  config_path = "../../network/sg/ecs-container"
}

inputs = {
  service_name      = "interactive-translator"
  vpc_id            = dependency.vpc.outputs.vpc_id
  cluster_arn       = dependency.ecs_cluster.outputs.ecs_cluster_arn
  security_group_id = dependency.sg.outputs.security_group_id
  subnets           = dependency.vpc.outputs.private_subnets
  alb_listener_arn  = dependency.alb.outputs.https_listener_arns[0]
  alb_listener_rules = [
    {
      conditions = [{
        path_patterns = ["/itfirststep", "/itstep"]
      }]
    }
  ]
  health_check_matcher = "404"
  desired_count        = 1
  task_cpu             = 2048
  task_memory          = 8192
  container_port       = 5000
}
