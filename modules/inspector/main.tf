data "aws_caller_identity" "current" {}

resource "aws_inspector2_enabler" "this" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = var.resource_types
}

resource "aws_cloudwatch_event_rule" "findings" {
  count = var.notifications != null ? 1 : 0

  name        = "${var.name}-inspector-findings"
  description = "New Inspector findings with severity ${join(", ", var.notifications.severities)}"

  event_pattern = jsonencode({
    source      = ["aws.inspector2"]
    detail-type = ["Inspector2 Finding"]
    detail = {
      severity = var.notifications.severities
      status   = ["ACTIVE"]
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
      title    = "$.detail.title"
      account  = "$.account"
      region   = "$.region"
      resource = "$.detail.resources[0].id"
    }
    input_template = "\"Inspector <severity> in <account>/<region>: <title>. Resource <resource>\""
  }
}
