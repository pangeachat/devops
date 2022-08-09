variable "bucket_name" {
  type = string
}
variable "aliases" {
  type    = list(string)
  default = null
}

variable "origin_name" {
  type = string
}
variable "acm_certificate_arn" {
  type = string
}

variable "env" {
  type = string
}

variable "tags" {
  type    = map(any)
  default = {}
}

