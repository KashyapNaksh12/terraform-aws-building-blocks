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


resource "aws_s3_bucket" "this" {
  count = local.create_bucket ? 1 : 0

  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "config-retention"
    status = "Enabled"

    filter {}

    dynamic "expiration" {
      for_each = var.log_retention_days != null ? [var.log_retention_days] : []

      content {
        days = expiration.value
      }
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
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

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [local.bucket_arn, "${local.bucket_arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.bucket[0].json

  depends_on = [aws_s3_bucket_public_access_block.this]
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

  depends_on = [aws_config_configuration_recorder.this, aws_s3_bucket_policy.this, aws_iam_role_policy.delivery]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}
