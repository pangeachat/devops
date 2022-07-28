variable "name" {
  type        = string
  description = "The name of the container. Up to 255 characters ([a-z], [A-Z], [0-9], -, _ allowed)"
}

variable "image" {
  type        = string
  description = "The image used to start the container. Images in the Docker Hub registry available by default"
}

variable "memory" {
  type        = number
  description = "The amount of memory (in MiB) to allow the container to use. This is a hard limit, if the container attempts to exceed the container_memory, the container is killed. This field is optional for Fargate launch type and the total amount of container_memory of all containers in a task will need to be lower than the task memory value"
  default     = null
}

variable "portMappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))

  description = "The port mappings to configure for the container. This is a list of maps. Each map should contain \"containerPort\", \"hostPort\", and \"protocol\", where \"protocol\" is one of \"tcp\" or \"udp\". If using containers in a task with the awsvpc or host network mode, the hostPort can either be left blank or set to the same value as the containerPort"

  default = []
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_HealthCheck.html
variable "healthCheck" {
  type = object({
    command  = list(string)
    retries  = number
    timeout  = number
    interval = number
    # startPeriod = number
  })
  description = "A map containing command (string), timeout, interval (duration in seconds), retries (1-10, number of times to retry before marking container unhealthy), and startPeriod (0-300, optional grace period to wait, in seconds, before failed healthchecks count toward retries)"
  default     = null
}

variable "cpu" {
  type        = number
  description = "The number of cpu units to reserve for the container. This is optional for tasks using Fargate launch type and the total amount of container_cpu of all containers in a task will need to be lower than the task-level cpu value"
  default     = 0
}

variable "essential" {
  type        = bool
  description = "Determines whether all other containers in a task are stopped, if this container fails or stops for any reason. Due to how Terraform type casts booleans in json it is required to double quote this value"
  default     = true
}

variable "entrypoint" {
  type        = list(string)
  description = "The entry point that is passed to the container"
  default     = null
}

variable "command" {
  type        = list(string)
  description = "The command that is passed to the container"
  default     = null
}

variable "workingDirectory" {
  type        = string
  description = "The working directory to run commands inside the container"
  default     = null
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

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html
variable "logConfiguration" {
  type        = any
  description = "Log configuration options to send to a custom log driver for the container. For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html"
  default     = null
}

variable "mountPoints" {
  type = list(any)

  description = "Container mount points. This is a list of maps, where each map should contain a `containerPath` and `sourceVolume`. The `readOnly` key is optional."
  default     = []
}

variable "volumesFrom" {
  type = list(object({
    sourceContainer = string
    readOnly        = bool
  }))
  description = "A list of VolumesFrom maps which contain \"sourceContainer\" (name of the container that has the volumes to mount) and \"readOnly\" (whether the container can write to the volume)"
  default     = []
}

variable "links" {
  type        = list(string)
  description = "List of container names this container can communicate with without port mappings"
  default     = null
}

variable "startTimeout" {
  type        = number
  description = "Time duration (in seconds) to wait before giving up on resolving dependencies for a container"
  default     = null
}

variable "stopTimeout" {
  type        = number
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own"
  default     = 120
}
variable "ulimits" {
  type = list(object({
    name      = string
    hardLimit = number
    softLimit = number
  }))
  description = "Container ulimit settings. This is a list of maps, where each map should contain \"name\", \"hardLimit\" and \"softLimit\""
  default     = null
}
variable "docker_labels" {
  type        = map(string)
  description = "The configuration options to send to the `docker_labels`"
  default     = null
}
