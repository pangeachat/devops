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
  task_cpu       = 1024
  task_memory    = 2048
  container_port = 8000
  # command        = split(" ", "gunicorn pangeachat.wsgi:application --bind 0.0.0.0:8000 --workers 3 --worker-class=gevent --timeout=20")
  environment = {
    PROD_DB_NAME                = "pangea_prod_backend"
    PROD_USER                   = "pangea_prod_admin"
    PROD_PORT                   = "5432"
    DJANGO_SETTINGS_MODULE      = "pangeachat.settings.prod"
    DJANGO_ALLOWED_HOSTS        = "*"
    DJANGO_CSRF_TRUSTED_ORIGINS = "https://api.pangea.chat,https://app.pangea.chat"
  }
  secrets = {
    PROD_HOST          = "arn:aws:ssm:us-east-1:061565848348:parameter/prod/api/PROD_HOST"
    PROD_PASSWORD      = "arn:aws:ssm:us-east-1:061565848348:parameter/prod/api/PROD_PASSWORD"
    SECRET_KEY         = "arn:aws:ssm:us-east-1:061565848348:parameter/prod/api/SECRET_KEY"
    ADMIN_ACCESS_TOKEN = "arn:aws:ssm:us-east-1:061565848348:parameter/prod/api/ADMIN_ACCESS_TOKEN"
  }
}
