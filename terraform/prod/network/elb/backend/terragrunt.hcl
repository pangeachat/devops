include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  certificate_arn = "arn:aws:acm:us-east-1:061565848348:certificate/b5b06d44-8e4b-4fa4-8e3c-92a1d4cd4bf5"
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/alb/aws?version=6.4.0"
}
dependencies {
  paths = ["../../vpc", "../../sg/alb-backend"]
}

dependency "vpc" {
  config_path = "../../vpc"
}
dependency "sg" {
  config_path = "../../sg/alb-backend"
}


inputs = {


  name = "alb-pangea-${local.env_vars.env}-backend"

  load_balancer_type = "application"

  vpc_id          = dependency.vpc.outputs.vpc_id
  security_groups = [dependency.sg.outputs.security_group_id]
  subnets         = dependency.vpc.outputs.public_subnets

  #   # See notes in README (ref: https://github.com/terraform-providers/terraform-provider-aws/issues/7987)
  #   access_logs = {
  #     bucket = module.log_bucket.s3_bucket_id
  #   }



  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
  ]

  https_listeners = [
    {
      port        = 443
      protocol    = "HTTPS"
      action_type = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
      certificate_arn = local.certificate_arn
    },

  ]

}
