resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  tags = var.tags
}

resource "aws_guardduty_detector_feature" "this" {
  for_each = { for k, v in var.features : k => v if k != "RUNTIME_MONITORING" }

  detector_id = aws_guardduty_detector.this.id
  name        = each.key
  status      = each.value ? "ENABLED" : "DISABLED"
}

# runtime monitoring has its own agent settings, the agent is managed by GuardDuty
resource "aws_guardduty_detector_feature" "runtime" {
  count = contains(keys(var.features), "RUNTIME_MONITORING") ? 1 : 0

  detector_id = aws_guardduty_detector.this.id
  name        = "RUNTIME_MONITORING"
  status      = var.features["RUNTIME_MONITORING"] ? "ENABLED" : "DISABLED"

  dynamic "additional_configuration" {
    for_each = var.runtime_monitoring_agents

    content {
      name   = additional_configuration.key
      status = additional_configuration.value ? "ENABLED" : "DISABLED"
    }
  }
}

resource "aws_guardduty_publishing_destination" "this" {
  count = var.export_bucket_arn != null ? 1 : 0

  detector_id     = aws_guardduty_detector.this.id
  destination_arn = var.export_bucket_arn
  kms_key_arn     = var.export_kms_key_arn
}

resource "aws_cloudwatch_event_rule" "findings" {
  count = var.notifications != null ? 1 : 0

  name        = "${var.name}-guardduty-findings"
  description = "GuardDuty findings with severity >= ${var.notifications.min_severity}"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", var.notifications.min_severity] }]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "findings" {
  count = var.notifications != null ? 1 : 0

  rule = aws_cloudwatch_event_rule.findings[0].name
  arn  = var.notifications.sns_topic_arn

  input_transformer {
    input_paths = {
      severity = "$.detail.severity"
      type     = "$.detail.type"
      title    = "$.detail.title"
      account  = "$.detail.accountId"
      region   = "$.region"
      id       = "$.detail.id"
    }
    input_template = "\"GuardDuty severity <severity> in <account>/<region>: <title> (<type>). Finding <id>\""
  }
}
