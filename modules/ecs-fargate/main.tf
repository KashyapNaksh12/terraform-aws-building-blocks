locals {
  create_cluster = var.cluster_arn == null
  cluster_arn    = local.create_cluster ? aws_ecs_cluster.this[0].arn : var.cluster_arn
  cluster_name   = element(split("/", local.cluster_arn), length(split("/", local.cluster_arn)) - 1)
  has_port       = var.container.port != null
}

resource "aws_ecs_cluster" "this" {
  count = local.create_cluster ? 1 : 0

  name = var.name

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn

  tags = var.tags
}

module "roles" {
  source = "../ecs-task-roles"

  name                       = var.name
  secrets                    = var.container.secrets
  secrets_kms_key_arns       = var.secrets_kms_key_arns
  execution_role_policy_arns = var.execution_role_policy_arns
  task_role_policy_arns      = var.task_role_policy_arns
  task_role_inline_policy    = var.task_role_inline_policy
  enable_execute_command     = var.enable_execute_command

  tags = var.tags
}


resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = module.roles.execution_role_arn
  task_role_arn            = module.roles.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  container_definitions = jsonencode([
    {
      name                   = var.container.name
      image                  = var.container.image
      essential              = true
      command                = var.container.command
      readonlyRootFilesystem = var.container.readonly_root_filesystem

      portMappings = local.has_port ? [{
        containerPort = var.container.port
        protocol      = "tcp"
      }] : []

      environment = [for k, v in var.container.environment : { name = k, value = v }]
      secrets     = [for k, v in var.container.secrets : { name = k, valueFrom = v }]

      healthCheck = var.container.health_check_command != null ? {
        command     = var.container.health_check_command
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      } : null

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = split(":", aws_cloudwatch_log_group.this.arn)[3] # aws_region.name is deprecated in v6
          awslogs-stream-prefix = var.container.name
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-ecs-"
  description = "ECS service ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-ecs" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.has_port ? var.ingress_security_group_ids : {}

  security_group_id            = aws_security_group.this.id
  description                  = "Container port from ${each.key}"
  ip_protocol                  = "tcp"
  from_port                    = var.container.port
  to_port                      = var.container.port
  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound (image pulls, AWS APIs)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_ecs_service" "this" {
  name                   = var.name
  cluster                = local.cluster_arn
  task_definition        = aws_ecs_task_definition.this.arn
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  platform_version       = "LATEST"
  enable_execute_command = var.enable_execute_command
  propagate_tags         = "SERVICE"
  wait_for_steady_state  = var.wait_for_steady_state

  health_check_grace_period_seconds = var.target_group_arn != null ? var.health_check_grace_period : null

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = concat([aws_security_group.this.id], var.additional_security_group_ids)
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []

    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container.name
      container_port   = var.container.port
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = var.tags

  lifecycle {
    # autoscaling and manual scale-outs change this, don't fight them on every apply
    ignore_changes = [desired_count]

    precondition {
      condition     = var.target_group_arn == null || local.has_port
      error_message = "target_group_arn needs container.port to be set."
    }
  }
}

module "autoscaling" {
  count  = var.autoscaling != null ? 1 : 0
  source = "../ecs-autoscaling"

  name          = var.name
  cluster_name  = local.cluster_name
  service_name  = aws_ecs_service.this.name
  min_capacity  = var.autoscaling.min_capacity
  max_capacity  = var.autoscaling.max_capacity
  cpu_target    = var.autoscaling.cpu_target
  memory_target = var.autoscaling.memory_target

  tags = var.tags
}
