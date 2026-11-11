data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id

  create_bucket = var.s3_bucket_name == null
  bucket_name   = local.create_bucket ? coalesce(var.bucket_name, "${var.name}-cloudtrail-${local.account_id}") : var.s3_bucket_name
  bucket_arn    = "arn:${local.partition}:s3:::${local.bucket_name}"

  # region wildcard so the bucket policy doesn't depend on the trail (it has to exist first)
  trail_arn_pattern = "arn:${local.partition}:cloudtrail:*:${local.account_id}:trail/${var.name}"

  key_prefix  = var.s3_key_prefix != null ? "${var.s3_key_prefix}/" : ""
  log_paths   = concat(["${local.bucket_arn}/${local.key_prefix}AWSLogs/${local.account_id}/*"], var.organization_id != null ? ["${local.bucket_arn}/${local.key_prefix}AWSLogs/${var.organization_id}/*"] : [])
  create_logs = var.cloudwatch_logs_enabled
}


data "aws_iam_policy_document" "bucket" {
  count = local.create_bucket ? 1 : 0

  statement {
    sid       = "CloudTrailAclCheck"
    actions   = ["s3:GetBucketAcl"]
    resources = [local.bucket_arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [local.trail_arn_pattern]
    }
  }

  statement {
    sid       = "CloudTrailWrite"
    actions   = ["s3:PutObject"]
    resources = local.log_paths

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [local.trail_arn_pattern]
    }
  }
}

module "bucket" {
  count  = local.create_bucket ? 1 : 0
  source = "../log-bucket"

  bucket_name           = local.bucket_name
  force_destroy         = var.force_destroy
  kms_key_arn           = var.kms_key_arn
  object_lock           = var.object_lock
  access_logging_bucket = var.access_logging_bucket
  deny_object_deletion  = var.deny_log_deletion

  lifecycle_rule_id       = "cloudtrail-retention"
  glacier_transition_days = var.glacier_transition_days
  retention_days          = var.log_retention_days

  source_policy_documents = [data.aws_iam_policy_document.bucket[0].json]

  tags = var.tags
}


resource "aws_cloudwatch_log_group" "this" {
  count = local.create_logs ? 1 : 0

  name              = "/aws/cloudtrail/${var.name}"
  retention_in_days = var.cloudwatch_logs_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "logs" {
  count = local.create_logs ? 1 : 0

  name               = "${var.name}-cloudtrail-logs"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "logs" {
  count = local.create_logs ? 1 : 0

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.this[0].arn}:log-stream:*"]
  }
}

resource "aws_iam_role_policy" "logs" {
  count = local.create_logs ? 1 : 0

  name   = "cloudwatch-logs"
  role   = aws_iam_role.logs[0].id
  policy = data.aws_iam_policy_document.logs[0].json
}


resource "aws_cloudtrail" "this" {
  name                          = var.name
  s3_bucket_name                = local.bucket_name
  s3_key_prefix                 = var.s3_key_prefix
  kms_key_id                    = var.kms_key_arn
  is_multi_region_trail         = var.is_multi_region_trail
  is_organization_trail         = var.is_organization_trail
  include_global_service_events = true
  enable_log_file_validation    = true
  enable_logging                = true
  sns_topic_name                = var.sns_topic_arn

  cloud_watch_logs_group_arn = local.create_logs ? "${aws_cloudwatch_log_group.this[0].arn}:*" : null
  cloud_watch_logs_role_arn  = local.create_logs ? aws_iam_role.logs[0].arn : null

  # management events always, data events on top if asked for
  advanced_event_selector {
    name = "Management events"

    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }

  dynamic "advanced_event_selector" {
    for_each = var.s3_data_events ? [1] : []

    content {
      name = "S3 data events"

      field_selector {
        field  = "eventCategory"
        equals = ["Data"]
      }

      field_selector {
        field  = "resources.type"
        equals = ["AWS::S3::Object"]
      }

      # don't log the trail writing its own logs
      field_selector {
        field           = "resources.ARN"
        not_starts_with = ["${local.bucket_arn}/"]
      }
    }
  }

  dynamic "advanced_event_selector" {
    for_each = var.lambda_data_events ? [1] : []

    content {
      name = "Lambda data events"

      field_selector {
        field  = "eventCategory"
        equals = ["Data"]
      }

      field_selector {
        field  = "resources.type"
        equals = ["AWS::Lambda::Function"]
      }
    }
  }

  dynamic "insight_selector" {
    for_each = var.insight_types

    content {
      insight_type = insight_selector.value
    }
  }

  tags = merge(var.tags, { Name = var.name })

  depends_on = [module.bucket, aws_iam_role_policy.logs]
}
