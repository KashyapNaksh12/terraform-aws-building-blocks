locals {
  partition = split(":", aws_securityhub_account.this.arn)[1]
  # region from the hub ARN, aws_region.name is deprecated in v6
  region = split(":", aws_securityhub_account.this.arn)[3]

  standards_arns = { for s in var.standards : s => "arn:${local.partition}:securityhub:${local.region}::standards/${s}" }
}

resource "aws_securityhub_account" "this" {
  enable_default_standards  = false
  auto_enable_controls      = true
  control_finding_generator = "SECURITY_CONTROL"
}

resource "aws_securityhub_standards_subscription" "this" {
  for_each = toset(var.standards)

  standards_arn = local.standards_arns[each.key]

  depends_on = [aws_securityhub_account.this]
}

# documented exceptions, the reason shows up in the console for the auditor
resource "aws_securityhub_standards_control_association" "disabled" {
  for_each = var.disabled_controls

  standards_arn       = local.standards_arns[each.value.standard]
  security_control_id = each.value.control_id
  association_status  = "DISABLED"
  updated_reason      = each.value.reason

  depends_on = [aws_securityhub_standards_subscription.this]
}

resource "aws_securityhub_finding_aggregator" "this" {
  count = var.aggregate_regions != null ? 1 : 0

  linking_mode      = length(var.aggregate_regions) == 0 ? "ALL_REGIONS" : "SPECIFIED_REGIONS"
  specified_regions = length(var.aggregate_regions) == 0 ? null : var.aggregate_regions

  depends_on = [aws_securityhub_account.this]
}

resource "aws_cloudwatch_event_rule" "findings" {
  count = var.notifications != null ? 1 : 0

  name        = "${var.name}-securityhub-findings"
  description = "New Security Hub findings with severity ${join(", ", var.notifications.severities)}"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity    = { Label = var.notifications.severities }
        Workflow    = { Status = ["NEW"] }
        RecordState = ["ACTIVE"]
      }
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
      severity = "$.detail.findings[0].Severity.Label"
      title    = "$.detail.findings[0].Title"
      account  = "$.detail.findings[0].AwsAccountId"
      region   = "$.detail.findings[0].Region"
      resource = "$.detail.findings[0].Resources[0].Id"
    }
    input_template = "\"Security Hub <severity> in <account>/<region>: <title>. Resource <resource>\""
  }
}
