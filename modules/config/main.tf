data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id

  create_bucket = var.s3_bucket_name == null
  bucket_name   = local.create_bucket ? coalesce(var.bucket_name, "${var.name}-config-${local.account_id}") : var.s3_bucket_name
  bucket_arn    = "arn:${local.partition}:s3:::${local.bucket_name}"
  key_prefix    = var.s3_key_prefix != null ? "${var.s3_key_prefix}/" : ""
}


data "aws_iam_policy_document" "bucket" {
  count = local.create_bucket ? 1 : 0

  statement {
    sid       = "ConfigAclCheck"
    actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
    resources = [local.bucket_arn]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }

  statement {
    sid       = "ConfigWrite"
    actions   = ["s3:PutObject"]
    resources = ["${local.bucket_arn}/${local.key_prefix}AWSLogs/${local.account_id}/Config/*"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

module "bucket" {
  count  = local.create_bucket ? 1 : 0
  source = "../log-bucket"

  bucket_name   = local.bucket_name
  force_destroy = var.force_destroy
  kms_key_arn   = var.kms_key_arn

  lifecycle_rule_id = "config-retention"
  retention_days    = var.log_retention_days

  source_policy_documents = [data.aws_iam_policy_document.bucket[0].json]

  tags = var.tags
}


data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "this" {
  count = var.role_arn == null ? 1 : 0

  name               = "${var.name}-config"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  count = var.role_arn == null ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWS_ConfigRole"
}

data "aws_iam_policy_document" "delivery" {
  count = var.role_arn == null ? 1 : 0

  statement {
    actions   = ["s3:PutObject", "s3:PutObjectAcl"]
    resources = ["${local.bucket_arn}/${local.key_prefix}AWSLogs/${local.account_id}/*"]

    condition {
      test     = "StringLike"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    actions   = ["s3:GetBucketAcl"]
    resources = [local.bucket_arn]
  }

  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []

    content {
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = [var.kms_key_arn]
    }
  }

  dynamic "statement" {
    for_each = var.sns_topic_arn != null ? [1] : []

    content {
      actions   = ["sns:Publish"]
      resources = [var.sns_topic_arn]
    }
  }
}

resource "aws_iam_role_policy" "delivery" {
  count = var.role_arn == null ? 1 : 0

  name   = "delivery"
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.delivery[0].json
}

resource "aws_config_configuration_recorder" "this" {
  name     = var.name
  role_arn = var.role_arn != null ? var.role_arn : aws_iam_role.this[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = var.include_global_resources
  }

  recording_mode {
    recording_frequency = var.recording_frequency
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = var.name
  s3_bucket_name = local.bucket_name
  s3_key_prefix  = var.s3_key_prefix
  s3_kms_key_arn = var.kms_key_arn
  sns_topic_arn  = var.sns_topic_arn

  snapshot_delivery_properties {
    delivery_frequency = var.snapshot_frequency
  }

  depends_on = [aws_config_configuration_recorder.this, module.bucket, aws_iam_role_policy.delivery]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}
