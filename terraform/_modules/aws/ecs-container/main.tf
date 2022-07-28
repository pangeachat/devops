locals {
  env_vars_keys        = var.environment != null ? keys(var.environment) : []
  env_vars_values      = var.environment != null ? values(var.environment) : []
  env_vars_as_map      = zipmap(local.env_vars_keys, local.env_vars_values)
  sorted_env_vars_keys = sort(local.env_vars_keys)

  sorted_environment_vars = [
    for key in local.sorted_env_vars_keys :
    {
      name  = key
      value = lookup(local.env_vars_as_map, key)
    }
  ]

  mount_points = length(var.mountPoints) > 0 ? [
    for mount_point in var.mountPoints : {
      containerPath = lookup(mount_point, "containerPath")
      sourceVolume  = lookup(mount_point, "sourceVolume")
      readOnly      = tobool(lookup(mount_point, "readOnly", null))
    }
  ] : []

  # https://www.terraform.io/docs/configuration/expressions.html#null
  final_environment_vars = length(local.sorted_environment_vars) > 0 ? local.sorted_environment_vars : null

  log_configuration_with_null = var.logConfiguration == null ? null : {
    logDriver = tostring(lookup(var.logConfiguration, "logDriver"))
    options   = tomap(lookup(var.logConfiguration, "options"))
  }
  log_configuration_without_null = local.log_configuration_with_null == null ? null : {
    for k, v in local.log_configuration_with_null :
    k => v
    if v != null
  }
  container_definition = {
    name             = var.name
    image            = var.image
    essential        = var.essential
    entrypoint       = var.entrypoint
    command          = var.command
    workingDirectory = var.workingDirectory
    mountPoints      = local.mount_points
    links            = var.links
    volumesFrom      = var.volumesFrom
    portMappings     = var.portMappings
    healthCheck      = var.healthCheck
    logConfiguration = local.log_configuration_without_null
    memory           = var.memory
    cpu              = var.cpu
    dockerLabels     = var.docker_labels
    environment      = local.final_environment_vars
    startTimeout     = var.startTimeout
    stopTimeout      = var.stopTimeout
    ulimits          = var.ulimits
  }

  container_definition_without_null = {
    for k, v in local.container_definition :
    k => v
    if v != null
  }
  json_map = jsonencode(local.container_definition_without_null)
}
