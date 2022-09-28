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
  service_name      = "2stepchoreo"
  vpc_id            = dependency.vpc.outputs.vpc_id
  cluster_arn       = dependency.ecs_cluster.outputs.ecs_cluster_arn
  security_group_id = dependency.sg.outputs.security_group_id
  subnets           = dependency.vpc.outputs.private_subnets
  alb_listener_arn  = dependency.alb.outputs.https_listener_arns[0]
  alb_listener_rules = [
    {
      conditions = [{
        path_patterns = ["/choreo", "/choreo/*"]
      }]
    }
  ]
  health_check_matcher = "404"
  desired_count        = 0
  task_cpu             = 512
  task_memory          = 4096
  container_port       = 5000

  environment = {
    API_URL                 = "https://api.staging.pangea.chat"
    DB_NAME                 = "pangea_staging_learner"
    DB_USER                 = "pangea_staging_admin"
    DB_PORT                 = "5432"
    LANGUAGE_TOOL_USER      = "wcjord@email.wm.edu"
  }
  secrets = {
    DB_HOST     = "arn:aws:ssm:us-east-1:061565848348:parameter/staging/2stepchoreo/learner_db_host"
    DB_PASSWORD = "arn:aws:ssm:us-east-1:061565848348:parameter/staging/2stepchoreo/learner_db_pass"
    API_KEY = "arn:aws:ssm:us-east-1:061565848348:parameter/staging/2stepchoreo/api_key"
    LANGUAGE_TOOL_API_KEY = "arn:aws:ssm:us-east-1:061565848348:parameter/staging/2stepchoreo/language_tool_api_key"
  }
  capacity_provider_strategies = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
    }
  ]

}
