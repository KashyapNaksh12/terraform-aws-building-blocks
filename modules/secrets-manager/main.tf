resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  name_prefix             = var.name_prefix
  description             = var.description
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.recovery_window_in_days

  dynamic "replica" {
    for_each = var.replica_regions

    content {
      region     = replica.key
      kms_key_id = replica.value
    }
  }

  tags = merge(var.tags, { Name = coalesce(var.name, var.name_prefix) })

  lifecycle {
    precondition {
      condition     = (var.name == null) != (var.name_prefix == null)
      error_message = "Set exactly one of name or name_prefix."
    }

    precondition {
      condition     = !var.create_value || var.secret_string != null
      error_message = "create_value needs secret_string."
    }
  }
}

resource "aws_secretsmanager_secret_policy" "this" {
  count = var.policy != null ? 1 : 0

  secret_arn          = aws_secretsmanager_secret.this.arn
  policy              = var.policy
  block_public_policy = true
}

# value is in state, mark the input sensitive. ignore_value_changes lets
# the app or rotation own the value after the first apply
resource "aws_secretsmanager_secret_version" "this" {
  count = var.create_value && !var.ignore_value_changes ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string
}

resource "aws_secretsmanager_secret_version" "ignore_changes" {
  count = var.create_value && var.ignore_value_changes ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret_rotation" "this" {
  count = var.rotation_lambda_arn != null ? 1 : 0

  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_schedule_expression == null ? var.rotation_days : null
    schedule_expression      = var.rotation_schedule_expression
  }

  depends_on = [
    aws_secretsmanager_secret_version.this,
    aws_secretsmanager_secret_version.ignore_changes,
  ]
}
