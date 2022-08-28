variable "vpc_id" {
  type = string
}
variable "cluster_arn" {
  type = string
}
variable "subnets" {
  type = list(string)
}
variable "assign_public_ip" {
  type    = bool
  default = false
}
variable "alb_listener_arn" {
  type    = string
  default = ""
}
variable "sd_namespace_id" {
  type    = string
  default = ""
}
variable "env" {
  description = "staging, prod"
  type        = string
}
variable "service_name" {
  description = "Ecs service name"
  type        = string
}

variable "task_cpu" {
  type        = number
  description = "CPU Unit for ecs task"
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Memory in MB for ecs task"
  default     = 512
}

variable "task_role_arn" {
  type        = string
  description = "The ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services"
  default     = ""
}

variable "container_port" {
  type    = number
  default = 80
}
variable "desired_count" {
  type        = number
  description = "The number of instances of the task definition to place and keep running"
  default     = 1
}
variable "environment" {
  type        = map(string)
  description = "The environment variables to pass to the container. This is a map of string: {key: value}. map_environment overrides environment"
  default     = null
}
variable "secrets" {
  type        = map(string)
  description = "This is a map of string with the name of environment variables and the full arn of SSM containing the sensitive data to present to the container."
  default     = null
}

# ECS Service

variable "deployment_maximum_percent" {
  type        = number
  description = "The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment"
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment"
  default     = 100
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers"
  default     = 20
}
variable "alb_listener_rules" {
  type        = any
  description = "A list of load balancer config objects for the ECS service; see [ecs_service#load_balancer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service#load_balancer) docs"
  default     = []
}

variable "create_service_discovery" {
  type    = bool
  default = false
}

variable "task_execution_role_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(any)
  default = null
}

variable "command" {
  type        = list(string)
  description = "The command that is passed to the container"
  default     = null
}

variable "run_task" {
  type        = bool
  description = "The condition to run task"
  default     = false
}
variable "network_mode" {
  type    = string
  default = "awsvpc"
}

variable "entrypoint" {
  type        = list(string)
  description = "The entry point that is passed to the container"
  default     = null
}
variable "security_group_id" {
  type    = string
  default = ""
}
variable "requires_compatibilities" {
  type = list(string)
  default = [
    "FARGATE"
  ]
}
variable "launch_type" {
  type    = string
  default = "FARGATE"
}
variable "health_check_matcher" {
  type    = string
  default = "200"
}

variable "health_check_path" {
  type    = string
  default = "/"
}
variable "capacity_provider_strategies" {
  type    = list(map(any))
  default = []
}
