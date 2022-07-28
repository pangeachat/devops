locals {
  env = "prod"
  // vpc
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  cidr            = "10.8.0.0/16"
  public_subnets  = ["10.8.0.0/24", "10.8.1.0/24", "10.8.2.0/24"]
  private_subnets = ["10.8.3.0/24", "10.8.4.0/24", "10.8.5.0/24"]
}
inputs = {
  env             = local.env
  azs             = local.azs
  cidr            = local.cidr
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
}
