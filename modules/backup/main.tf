data "aws_partition" "current" {}

locals {
  partition = data.aws_partition.current.partition
}


resource "aws_backup_vault" "this" {
  name          = var.name
  kms_key_arn   = var.kms_key_arn
  force_destroy = var.force_destroy

  tags = var.tags
}

# COMPLIANCE mode once changeable_for_days is over, after that nobody can delete
# recovery points early or remove the lock, not even root
resource "aws_backup_vault_lock_configuration" "this" {
  count = var.vault_lock != null ? 1 : 0

  backup_vault_name   = aws_backup_vault.this.name
  min_retention_days  = var.vault_lock.min_retention_days
  max_retention_days  = var.vault_lock.max_retention_days
  changeable_for_days = var.vault_lock.changeable_for_days
}


resource "aws_backup_plan" "this" {
  name = var.name

  dynamic "rule" {
    for_each = var.rules

    content {
      rule_name                    = rule.key
      target_vault_name            = aws_backup_vault.this.name
      schedule                     = rule.value.schedule
      schedule_expression_timezone = rule.value.timezone
      start_window                 = rule.value.start_window
      completion_window            = rule.value.completion_window
      enable_continuous_backup     = rule.value.continuous_backup

      lifecycle {
        delete_after       = rule.value.delete_after
        cold_storage_after = rule.value.cold_storage_after
      }

      dynamic "copy_action" {
        for_each = rule.value.copy_to

        content {
          destination_vault_arn = copy_action.value.vault_arn

          lifecycle {
            delete_after       = coalesce(copy_action.value.delete_after, rule.value.delete_after)
            cold_storage_after = copy_action.value.cold_storage_after
          }
        }
      }

      recovery_point_tags = merge(var.tags, { BackupRule = rule.key })
    }
  }

  dynamic "advanced_backup_setting" {
    for_each = var.windows_vss ? [1] : []

    content {
      resource_type  = "EC2"
      backup_options = { WindowsVSS = "enabled" }
    }
  }

  tags = var.tags
}


data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count = var.role_arn == null ? 1 : 0

  name               = "${var.name}-backup"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.role_arn == null ? toset([
    "service-role/AWSBackupServiceRolePolicyForBackup",
    "service-role/AWSBackupServiceRolePolicyForRestores",
    "AWSBackupServiceRolePolicyForS3Backup",
    "AWSBackupServiceRolePolicyForS3Restore",
  ]) : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/${each.value}"
}


resource "aws_backup_selection" "this" {
  count = var.selection_tag != null || length(var.resource_arns) > 0 ? 1 : 0

  name         = var.name
  plan_id      = aws_backup_plan.this.id
  iam_role_arn = var.role_arn != null ? var.role_arn : aws_iam_role.this[0].arn
  resources    = length(var.resource_arns) > 0 ? values(var.resource_arns) : ["*"]

  dynamic "condition" {
    for_each = var.selection_tag != null ? [var.selection_tag] : []

    content {
      string_equals {
        key   = "aws:ResourceTag/${condition.value.key}"
        value = condition.value.value
      }
    }
  }

  depends_on = [aws_iam_role_policy_attachment.this]
}


resource "aws_cloudwatch_event_rule" "failed" {
  count = var.notifications != null ? 1 : 0

  name        = "${var.name}-backup-failed"
  description = "Backup or copy jobs in ${var.name} that did not complete"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change", "Copy Job State Change", "Restore Job State Change"]
    detail = {
      state = ["FAILED", "ABORTED", "EXPIRED"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "failed" {
  count = var.notifications != null ? 1 : 0

  rule = aws_cloudwatch_event_rule.failed[0].name
  arn  = var.notifications.sns_topic_arn

  input_transformer {
    input_paths = {
      type     = "$.detail-type"
      state    = "$.detail.state"
      resource = "$.detail.resourceArn"
      vault    = "$.detail.backupVaultName"
      message  = "$.detail.statusMessage"
    }
    input_template = "\"<type>: <state> for <resource> (vault <vault>). <message>\""
  }
}
