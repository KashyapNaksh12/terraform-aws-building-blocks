data "aws_caller_identity" "current" {}

locals {
  name = var.fifo_topic ? "${trimsuffix(var.name, ".fifo")}.fifo" : var.name
}

resource "aws_sns_topic" "this" {
  name                        = local.name
  display_name                = var.display_name
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null
  kms_master_key_id           = var.kms_key_arn
  delivery_policy             = var.delivery_policy

  tags = merge(var.tags, { Name = local.name })
}

data "aws_iam_policy_document" "this" {
  source_policy_documents = var.policy != null ? [var.policy] : []

  # same as the default topic policy, owner account only
  statement {
    sid = "AccountOwner"
    actions = [
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:AddPermission",
      "sns:RemovePermission",
      "sns:DeleteTopic",
      "sns:Subscribe",
      "sns:ListSubscriptionsByTopic",
      "sns:Publish",
    ]
    resources = [aws_sns_topic.this.arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.this.arn]

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

  dynamic "statement" {
    for_each = length(var.publisher_service_principals) > 0 ? [1] : []

    content {
      sid       = "AllowServicePublish"
      actions   = ["sns:Publish"]
      resources = [aws_sns_topic.this.arn]

      principals {
        type        = "Service"
        identifiers = values(var.publisher_service_principals)
      }

      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
}

resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_sns_topic_subscription" "this" {
  for_each = var.subscriptions

  topic_arn            = aws_sns_topic.this.arn
  protocol             = each.value.protocol
  endpoint             = each.value.endpoint
  raw_message_delivery = each.value.raw_message_delivery
  filter_policy        = each.value.filter_policy
  filter_policy_scope  = each.value.filter_policy != null ? each.value.filter_policy_scope : null
  redrive_policy       = each.value.dlq_arn != null ? jsonencode({ deadLetterTargetArn = each.value.dlq_arn }) : null
}
