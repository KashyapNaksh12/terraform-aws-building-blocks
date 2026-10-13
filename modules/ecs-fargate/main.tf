locals {
  create_cluster = var.cluster_arn == null
  cluster_arn    = local.create_cluster ? aws_ecs_cluster.this[0].arn : var.cluster_arn
  cluster_name   = element(split("/", local.cluster_arn), length(split("/", local.cluster_arn)) - 1)
  has_port       = var.container.port != null

  # secrets manager ARNs can carry a json-key suffix (arn:...:secret:name:key::),
  # IAM only matches the bare secret ARN
  secret_arns = distinct([
    for arn in values(var.container.secrets) : join(":", slice(split(":", arn), 0, 7))
    if strcontains(arn, ":secretsmanager:")
  ])
  parameter_arns = distinct([for arn in values(var.container.secrets) : arn if strcontains(arn, ":ssm:")])
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

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

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# execution role: used by the ECS agent to pull the image, write logs and
# fetch secrets before the container starts
resource "aws_iam_role" "execution" {
  name_prefix        = "${substr(var.name, 0, 26)}-exec-"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  for_each = merge(
    { ecs = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" },
    var.execution_role_policy_arns,
  )

  role       = aws_iam_role.execution.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "secrets" {
  count = length(var.container.secrets) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = length(local.secret_arns) > 0 ? [1] : []

    content {
      actions   = ["secretsmanager:GetSecretValue"]
      resources = local.secret_arns
    }
  }

  dynamic "statement" {
    for_each = length(local.parameter_arns) > 0 ? [1] : []

    content {
      actions   = ["ssm:GetParameters"]
      resources = local.parameter_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.secrets_kms_key_arns) > 0 ? [1] : []

    content {
      actions   = ["kms:Decrypt"]
      resources = values(var.secrets_kms_key_arns)
    }
  }
}

resource "aws_iam_role_policy" "secrets" {
  count = length(var.container.secrets) > 0 ? 1 : 0

  name   = "secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.secrets[0].json
}

# task role: what the app itself can do
resource "aws_iam_role" "task" {
  name_prefix        = "${substr(var.name, 0, 26)}-task-"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task" {
  for_each = var.task_role_policy_arns

  role       = aws_iam_role.task.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "task" {
  count = var.task_role_inline_policy != null ? 1 : 0

  name   = "inline"
  role   = aws_iam_role.task.id
  policy = var.task_role_inline_policy
}

data "aws_iam_policy_document" "exec" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "exec" {
  count = var.enable_execute_command ? 1 : 0

  name   = "ecs-exec"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.exec.json
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

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

resource "aws_appautoscaling_target" "this" {
  count = var.autoscaling != null ? 1 : 0

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${local.cluster_name}/${aws_ecs_service.this.name}"
  min_capacity       = var.autoscaling.min_capacity
  max_capacity       = var.autoscaling.max_capacity

  tags = var.tags
}

resource "aws_appautoscaling_policy" "cpu" {
  count = var.autoscaling != null ? 1 : 0

  name               = "${var.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.this[0].resource_id

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling.cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count = try(var.autoscaling.memory_target, null) != null ? 1 : 0

  name               = "${var.name}-memory"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.this[0].resource_id

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling.memory_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}
