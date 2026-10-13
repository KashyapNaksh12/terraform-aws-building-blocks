data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_root = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
  # region from the key ARN, aws_region.name is deprecated in v6
  region = split(":", aws_kms_key.this.arn)[3]
}

resource "aws_kms_key" "this" {
  description              = var.description
  key_usage                = var.key_usage
  customer_master_key_spec = var.key_spec
  multi_region             = var.multi_region
  enable_key_rotation      = var.key_spec == "SYMMETRIC_DEFAULT" ? var.enable_key_rotation : false
  rotation_period_in_days  = var.key_spec == "SYMMETRIC_DEFAULT" && var.enable_key_rotation ? var.rotation_period_in_days : null
  deletion_window_in_days  = var.deletion_window_in_days

  tags = merge(var.tags, { Name = var.alias })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${trimprefix(var.alias, "alias/")}"
  target_key_id = aws_kms_key.this.key_id
}

data "aws_iam_policy_document" "this" {
  source_policy_documents = var.policy != null ? [var.policy] : []

  # keeps IAM in charge, without this the key can lock everyone out
  statement {
    sid       = "AccountRoot"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [local.account_root]
    }
  }

  dynamic "statement" {
    for_each = length(var.admin_arns) > 0 ? [1] : []

    content {
      sid = "KeyAdmins"
      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
        "kms:RotateKeyOnDemand",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = values(var.admin_arns)
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.user_arns) > 0 ? [1] : []

    content {
      sid = "KeyUsers"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = values(var.user_arns)
      }
    }
  }

  # lets AWS services (RDS, EBS, Secrets Manager...) create grants on behalf of the users
  dynamic "statement" {
    for_each = length(var.user_arns) > 0 ? [1] : []

    content {
      sid       = "KeyUsersGrants"
      actions   = ["kms:CreateGrant", "kms:ListGrants", "kms:RevokeGrant"]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = values(var.user_arns)
      }

      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = ["true"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.allow_cloudwatch_logs ? [1] : []

    content {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*",
      ]
      resources = ["*"]

      principals {
        type        = "Service"
        identifiers = ["logs.${local.region}.amazonaws.com"]
      }

      condition {
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = ["arn:${data.aws_partition.current.partition}:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:*"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.service_principals

    content {
      sid = "Service${replace(statement.key, "/[^a-zA-Z0-9]/", "")}"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
      resources = ["*"]

      principals {
        type        = "Service"
        identifiers = [statement.value]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
}

# separate resource so the policy can use the region from the key ARN
resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.id
  policy = data.aws_iam_policy_document.this.json
}
