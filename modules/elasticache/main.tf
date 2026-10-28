locals {
  create_subnet_group = var.subnet_group_name == null
  subnet_group_name   = local.create_subnet_group ? aws_elasticache_subnet_group.this[0].name : var.subnet_group_name
  multi_node          = var.cluster_mode_enabled || var.replicas_per_node_group > 0
}

resource "aws_elasticache_subnet_group" "this" {
  count = local.create_subnet_group ? 1 : 0

  name        = var.name
  description = "Subnet group for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    precondition {
      condition     = length(var.subnet_ids) >= 1
      error_message = "Provide subnet_group_name or subnet_ids."
    }
  }
}

resource "aws_elasticache_parameter_group" "this" {
  count = var.parameter_group_family != null ? 1 : 0

  name   = var.name
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters

    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "slow_log" {
  count = var.enable_slow_log ? 1 : 0

  name              = "/aws/elasticache/${var.name}/slow-log"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn

  tags = var.tags
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.name
  description          = var.description
  engine               = var.engine
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = var.port
  parameter_group_name = try(aws_elasticache_parameter_group.this[0].name, var.parameter_group_name)

  num_node_groups         = var.cluster_mode_enabled ? var.num_node_groups : null
  replicas_per_node_group = var.replicas_per_node_group
  cluster_mode            = var.cluster_mode_enabled ? "enabled" : "disabled"

  automatic_failover_enabled = local.multi_node
  multi_az_enabled           = local.multi_node && var.multi_az_enabled

  subnet_group_name  = local.subnet_group_name
  security_group_ids = var.security_group_ids

  at_rest_encryption_enabled = true
  kms_key_id                 = var.kms_key_arn
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"
  auth_token                 = var.auth_token
  auth_token_update_strategy = var.auth_token != null ? "ROTATE" : null
  user_group_ids             = length(var.user_group_ids) > 0 ? var.user_group_ids : null

  snapshot_retention_limit  = var.snapshot_retention_limit
  snapshot_window           = var.snapshot_window
  maintenance_window        = var.maintenance_window
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final"

  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  notification_topic_arn     = var.notification_topic_arn

  dynamic "log_delivery_configuration" {
    for_each = var.enable_slow_log ? [1] : []

    content {
      destination      = aws_cloudwatch_log_group.slow_log[0].name
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "slow-log"
    }
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    precondition {
      condition     = var.auth_token == null || length(var.user_group_ids) == 0
      error_message = "Use either auth_token or user_group_ids, not both."
    }
  }
}
