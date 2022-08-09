include "root" {
  path = find_in_parent_folders()
}
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_parent_terragrunt_dir()}//_modules/aws/static-web"
}

inputs = {
  bucket_name         = "webapp"
  origin_name         = "webapp"
  aliases             = ["app.staging.pangea.chat"]
  acm_certificate_arn = "arn:aws:acm:us-east-1:061565848348:certificate/d338cb29-4e4a-4064-a841-e2a7aa43371e"
}
