locals {
  # managed groups first, then IP sets, then the rate limit
  ip_block_priority   = length(var.managed_rule_groups) + 1
  rate_limit_priority = length(var.managed_rule_groups) + 2
}

resource "aws_wafv2_ip_set" "block" {
  count = length(var.blocked_ip_cidrs) > 0 ? 1 : 0

  name               = "${var.name}-blocked"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.blocked_ip_cidrs

  tags = var.tags
}

resource "aws_wafv2_web_acl" "this" {
  name        = var.name
  description = var.description
  scope       = var.scope

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  dynamic "rule" {
    for_each = var.managed_rule_groups

    content {
      name     = rule.key
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.count_only ? [] : [1]
          content {}
        }

        dynamic "count" {
          for_each = rule.value.count_only ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name
          version     = rule.value.version

          # rules inside the group to only count, e.g. SizeRestrictions_BODY for uploads
          dynamic "rule_action_override" {
            for_each = toset(rule.value.excluded_rules)

            content {
              name = rule_action_override.value

              action_to_use {
                count {}
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name}-${rule.key}"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = length(var.blocked_ip_cidrs) > 0 ? [1] : []

    content {
      name     = "blocked-ips"
      priority = local.ip_block_priority

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.block[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name}-blocked-ips"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.rate_limit != null ? [1] : []

    content {
      name     = "rate-limit"
      priority = local.rate_limit_priority

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit                 = var.rate_limit
          aggregate_key_type    = "IP"
          evaluation_window_sec = var.rate_limit_window_sec
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name}-rate-limit"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled   = true
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    precondition {
      condition = alltrue([
        for g in values(var.managed_rule_groups) : g.priority < local.ip_block_priority
      ])
      error_message = "Managed rule group priorities must be lower than ${local.ip_block_priority} (number of groups + 1)."
    }
  }
}

# ALB, API Gateway stage, AppSync etc. For CloudFront set web_acl_id on the distribution instead
resource "aws_wafv2_web_acl_association" "this" {
  for_each = var.scope == "REGIONAL" ? var.resource_arns : {}

  resource_arn = each.value
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

# WAF requires the aws-waf-logs- prefix
resource "aws_cloudwatch_log_group" "this" {
  count = var.enable_logging ? 1 : 0

  name              = "aws-waf-logs-${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn

  tags = var.tags
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.enable_logging ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = [aws_cloudwatch_log_group.this[0].arn]

  dynamic "redacted_fields" {
    for_each = toset(var.redacted_headers)

    content {
      single_header {
        name = redacted_fields.value
      }
    }
  }
}
