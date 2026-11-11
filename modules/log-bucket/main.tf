locals {
  bucket_arn = aws_s3_bucket.this.arn
}

resource "aws_s3_bucket" "this" {
  bucket              = var.bucket_name
  force_destroy       = var.force_destroy
  object_lock_enabled = var.object_lock != null

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

resource "aws_s3_bucket_object_lock_configuration" "this" {
  count = var.object_lock != null ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    default_retention {
      mode = var.object_lock.mode
      days = var.object_lock.days
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = var.lifecycle_rule_id
    status = "Enabled"

    filter {}

    dynamic "transition" {
      for_each = var.glacier_transition_days != null ? [var.glacier_transition_days] : []

      content {
        days          = transition.value
        storage_class = "GLACIER"
      }
    }

    dynamic "expiration" {
      for_each = var.retention_days != null ? [var.retention_days] : []

      content {
        days = expiration.value
      }
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_logging" "this" {
  count = var.access_logging_bucket != null ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.access_logging_bucket
  target_prefix = "${var.bucket_name}/"
}

data "aws_iam_policy_document" "this" {
  source_policy_documents = var.source_policy_documents

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

  # nobody deletes objects by hand, lifecycle expiry still works
  dynamic "statement" {
    for_each = var.deny_object_deletion ? [1] : []

    content {
      sid       = "DenyObjectDeletion"
      effect    = "Deny"
      actions   = ["s3:DeleteObject", "s3:DeleteObjectVersion"]
      resources = ["${local.bucket_arn}/*"]

      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}
