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
  bucket_name = "webapp"
  origin_name = "webapp"
  aliases = [
    "app.pangea.chat",
  ]

  acm_certificate_arn = "arn:aws:acm:us-east-1:061565848348:certificate/83c5b5d3-3f7f-4972-83bd-3d8959452ef0"
}
