locals {
  prefix         = "pangea-${var.env}"
  service_name   = "${local.prefix}-${var.service_name}"
  container_name = "${local.prefix}-${var.service_name}"
  ecs_load_balancers = length(var.alb_listener_rules) > 0 ? [
    {
      container_name   = local.container_name
      container_port   = var.container_port
      target_group_arn = aws_lb_target_group.this[0].arn
    }
  ] : []
  service_registries = var.create_service_discovery ? [{
    registry_arn   = aws_service_discovery_service.this[0].arn
    container_name = local.container_name
  }] : []

  tags = var.tags
}


data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "this" {
  name                 = local.service_name
  image_tag_mutability = "MUTABLE"
}

resource "aws_ssm_parameter" "image_tag" {
  name  = "/${var.env}/${var.service_name}/IMAGE_TAG"
  type  = "String"
  value = "latest"
  lifecycle {
    ignore_changes = [value]
  }
}

module "container" {
  source = "../ecs-container"
  name   = local.service_name
  image  = "${aws_ecr_repository.this.repository_url}:${aws_ssm_parameter.image_tag.value}"
  portMappings = [
    {
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    },
  ]
  cpu    = var.task_cpu
  memory = var.task_memory
  logConfiguration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.this.name
      awslogs-region        = data.aws_region.current.name
      awslogs-stream-prefix = "container"
    }
  }
  secrets     = var.secrets
  environment = var.environment
  command     = var.command
  entrypoint  = var.entrypoint

}
resource "aws_ecs_task_definition" "this" {
  container_definitions = jsonencode([module.container.json_map_object])
  family                = local.service_name
  cpu                   = var.task_cpu
  memory                = var.task_memory
  network_mode          = var.network_mode
  execution_role_arn    = var.task_execution_role_arn != "" ? var.task_execution_role_arn : aws_iam_role.execution[0].arn
  task_role_arn         = var.task_role_arn == "" ? null : var.task_role_arn
  ipc_mode              = null
  pid_mode              = null

  requires_compatibilities = var.requires_compatibilities
  tags                     = {}
  tags_all                 = {}
}

resource "aws_ecs_service" "this" {
  count                              = var.run_task ? 0 : 1
  cluster                            = var.cluster_arn
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  desired_count                      = var.desired_count
  enable_ecs_managed_tags            = false
  enable_execute_command             = false
  health_check_grace_period_seconds  = length(var.alb_listener_rules) > 0 ? var.health_check_grace_period_seconds : null
  launch_type                        = var.launch_type
  scheduling_strategy                = "REPLICA"
  name                               = local.service_name
  tags                               = {}
  tags_all                           = {}
  task_definition                    = "${aws_ecs_task_definition.this.family}:${aws_ecs_task_definition.this.revision}"

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  deployment_controller {
    type = "ECS"
  }

  dynamic "service_registries" {
    for_each = local.service_registries
    content {
      registry_arn   = lookup(service_registries.value, "registry_arn", null)
      port           = lookup(service_registries.value, "port", null)
      container_name = lookup(service_registries.value, "container_name", null)
      container_port = lookup(service_registries.value, "container_port", null)
    }
  }
  dynamic "load_balancer" {
    for_each = local.ecs_load_balancers
    content {
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
      target_group_arn = load_balancer.value.target_group_arn
    }
  }
  network_configuration {
    security_groups = var.security_group_id == "" ? [
      aws_security_group.ecs[0].id
    ] : [var.security_group_id]
    subnets          = var.subnets
    assign_public_ip = var.assign_public_ip
  }
  timeouts {}

}

resource "aws_lb_target_group" "this" {
  count                         = length(var.alb_listener_rules) > 0 ? 1 : 0
  deregistration_delay          = 300
  load_balancing_algorithm_type = "round_robin"
  name                          = substr(local.service_name, 0, 32)
  port                          = var.container_port
  protocol                      = "HTTP"
  protocol_version              = "HTTP1"
  slow_start                    = 0
  tags                          = local.tags
  tags_all                      = local.tags
  target_type                   = "ip"
  vpc_id                        = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 25
    matcher             = var.health_check_matcher
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 20
    unhealthy_threshold = 2
  }

  stickiness {
    cookie_duration = 86400
    enabled         = false
    type            = "lb_cookie"
  }
}

resource "aws_lb_listener_rule" "this" {
  count        = length(var.alb_listener_rules)
  listener_arn = var.alb_listener_arn
  priority     = lookup(var.alb_listener_rules[count.index], "priority", null)

  # forward actions
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn

  }

  # Path Pattern condition
  dynamic "condition" {
    for_each = [
      for condition_rule in var.alb_listener_rules[count.index].conditions :
      condition_rule
      if length(lookup(condition_rule, "path_patterns", [])) > 0
    ]

    content {
      path_pattern {
        values = condition.value["path_patterns"]
      }
    }
  }

  # Host header condition
  dynamic "condition" {
    for_each = [
      for condition_rule in var.alb_listener_rules[count.index].conditions :
      condition_rule
      if length(lookup(condition_rule, "host_headers", [])) > 0
    ]

    content {
      host_header {
        values = condition.value["host_headers"]
      }
    }
  }

  tags = local.tags
}

resource "aws_service_discovery_service" "this" {
  count = var.create_service_discovery ? 1 : 0
  name  = var.service_name
  dns_config {
    namespace_id = var.sd_namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name = local.service_name
}

resource "aws_security_group" "ecs" {
  count  = var.security_group_id == "" ? 1 : 0
  name   = "${local.service_name}-ecs"
  vpc_id = var.vpc_id

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_iam_role" "execution" {
  count              = var.task_execution_role_arn == "" ? 1 : 0
  name               = "${local.service_name}-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "execution" {
  count = var.task_execution_role_arn == "" ? 1 : 0
  role  = aws_iam_role.execution[0].name
  # AWS Managed Policy
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ssm_policy" {
  count  = var.task_execution_role_arn == "" ? 1 : 0
  name   = "${local.service_name}-ssm-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeParameters"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "ssm:GetParameter"
      ],
      "Resource": "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/${var.env}/${var.service_name}/*"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "execution_ssm" {
  count      = var.task_execution_role_arn == "" ? 1 : 0
  role       = aws_iam_role.execution[0].name
  policy_arn = aws_iam_policy.ssm_policy[0].arn
}
