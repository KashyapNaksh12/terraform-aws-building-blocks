locals {
  suffix   = var.fifo_queue ? ".fifo" : ""
  name     = "${trimsuffix(var.name, ".fifo")}${local.suffix}"
  dlq_name = "${trimsuffix(var.name, ".fifo")}-dlq${local.suffix}"

  # KMS when a key is given, SQS-managed SSE otherwise
  sse_enabled = var.kms_key_arn == null
}

resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                        = local.dlq_name
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null
  message_retention_seconds   = var.dlq_message_retention_seconds

  sqs_managed_sse_enabled           = local.sse_enabled
  kms_master_key_id                 = var.kms_key_arn
  kms_data_key_reuse_period_seconds = var.kms_key_arn != null ? var.kms_data_key_reuse_period_seconds : null

  tags = merge(var.tags, { Name = local.dlq_name })
}

resource "aws_sqs_queue" "this" {
  name                        = local.name
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null
  deduplication_scope         = var.fifo_queue ? var.deduplication_scope : null
  fifo_throughput_limit       = var.fifo_queue ? var.fifo_throughput_limit : null

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  sqs_managed_sse_enabled           = local.sse_enabled
  kms_master_key_id                 = var.kms_key_arn
  kms_data_key_reuse_period_seconds = var.kms_key_arn != null ? var.kms_data_key_reuse_period_seconds : null

  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = merge(var.tags, { Name = local.name })
}

# only the main queue may send to the DLQ
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  count = var.create_dlq ? 1 : 0

  queue_url = aws_sqs_queue.dlq[0].id
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.this.arn]
  })
}

data "aws_iam_policy_document" "this" {
  source_policy_documents = var.policy != null ? [var.policy] : []

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.this.arn]

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
    for_each = length(var.sns_topic_arns) > 0 ? [1] : []

    content {
      sid       = "AllowSnsTopics"
      actions   = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.this.arn]

      principals {
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = values(var.sns_topic_arns)
      }
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.this.json
}
