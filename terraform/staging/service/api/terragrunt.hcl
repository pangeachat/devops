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
  service_name      = "api"
  vpc_id            = dependency.vpc.outputs.vpc_id
  cluster_arn       = dependency.ecs_cluster.outputs.ecs_cluster_arn
  security_group_id = dependency.sg.outputs.security_group_id
  subnets           = dependency.vpc.outputs.private_subnets
  alb_listener_arn  = dependency.alb.outputs.https_listener_arns[0]
  alb_listener_rules = [
    {
      conditions = [{
        path_patterns = ["/api/*", "/media/*", "/static/*"]
      }]
    }
  ]
  desired_count  = 1
  task_cpu       = 512
  task_memory    = 1024
  container_port = 8000
  # command        = split(" ", "gunicorn pangeachat.wsgi:application --bind 0.0.0.0:8000 --workers 3 --worker-class=gevent --timeout=20")
  environment = {
    STAGE_DB_NAME               = "pangea_staging_backend"
    STAGE_USER                  = "pangea_staging_admin"
    STAGE_PORT                  = "5432"
    DJANGO_SETTINGS_MODULE      = "pangeachat.settings.stage"
    DJANGO_ALLOWED_HOSTS        = "*"
    DJANGO_CSRF_TRUSTED_ORIGINS = "https://api.staging.pangea.chat,https://app.staging.pangea.chat"
  }
  secrets = {
    STAGE_HOST          = "arn:aws:ssm:us-east-1:061565848348:parameter/staging/api/STAGE_HOST"
    STAGE_PASSWORD      = "arn:aws:ssm:us-east-1:061565848348:parameter/staging/api/STAGE_PASSWORD"
    SECRET_KEY          = "arn:aws:ssm:us-east-1:061565848348:parameter/staging/api/SECRET_KEY"
    ADMIN_ACCESS_TOKEN 	= "arn:aws:ssm:us-east-1:061565848348:parameter/staging/api/ADMIN_ACCESS_TOKEN"
    EMAIL_HOST_USER	   	= "arn:aws:ssm:us-east-1:061565848348:parameter/staging/api/EMAIL_HOST_USER"
    EMAIL_HOST_PASSWORD = "arn:aws:ssm:us-east-1:061565848348:parameter/staging/api/EMAIL_HOST_PASSWORD"
  }
  capacity_provider_strategies = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
    }
  ]
}
