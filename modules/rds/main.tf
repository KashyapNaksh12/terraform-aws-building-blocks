locals {
  create_subnet_group  = var.db_subnet_group_name == null
  db_subnet_group_name = local.create_subnet_group ? aws_db_subnet_group.this[0].name : var.db_subnet_group_name
}

resource "aws_db_subnet_group" "this" {
  count = local.create_subnet_group ? 1 : 0

  name_prefix = "${var.identifier}-"
  description = "Subnet group for ${var.identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, { Name = var.identifier })

  lifecycle {
    precondition {
      condition     = length(var.subnet_ids) >= 2
      error_message = "Provide db_subnet_group_name or at least two subnet_ids in different AZs."
    }
  }
}

resource "aws_db_parameter_group" "this" {
  count = var.parameter_group_family != null ? 1 : 0

  name_prefix = "${var.identifier}-"
  family      = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "monitoring_assume" {
  count = var.monitoring_interval > 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name_prefix        = "${substr(var.identifier, 0, 25)}-mon-"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume[0].json

  tags = var.tags
}

data "aws_partition" "current" {}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = var.kms_key_id

  db_name  = var.db_name
  username = var.username
  port     = var.port

  # RDS generates the password and keeps it in Secrets Manager, so it stays out of state
  manage_master_user_password = true

  db_subnet_group_name   = local.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  parameter_group_name   = try(aws_db_parameter_group.this[0].name, null)
  multi_az               = var.multi_az
  publicly_accessible    = var.publicly_accessible

  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final"

  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  performance_insights_enabled        = var.performance_insights_enabled
  monitoring_interval                 = var.monitoring_interval
  monitoring_role_arn                 = try(aws_iam_role.monitoring[0].arn, null)
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  iam_database_authentication_enabled = contains(["postgres", "mysql"], var.engine)

  tags = merge(var.tags, { Name = var.identifier })

  depends_on = [aws_iam_role_policy_attachment.monitoring]
}
