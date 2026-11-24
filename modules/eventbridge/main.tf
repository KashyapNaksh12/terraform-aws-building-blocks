resource "aws_cloudwatch_event_bus" "this" {
  name        = var.name
  description = var.description
  tags        = merge(var.tags, { Name = var.name })
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = var.rules

  name                = each.key
  description         = each.value.description
  event_bus_name      = aws_cloudwatch_event_bus.this.name
  event_pattern       = each.value.event_pattern
  schedule_expression = each.value.schedule_expression
  state               = each.value.state
}

locals {
  targets = {
    for target in flatten([
      for rule_name, rule in var.rules : [
        for target_name, target in rule.targets : merge(target, {
          key       = "${rule_name}/${target_name}"
          rule_name = rule_name
          target_id = target_name
        })
      ]
    ]) : target.key => target
  }
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = local.targets

  event_bus_name = aws_cloudwatch_event_bus.this.name
  rule           = aws_cloudwatch_event_rule.this[each.value.rule_name].name
  target_id      = each.value.target_id
  arn            = each.value.arn
  role_arn       = each.value.role_arn
  input          = each.value.input
  input_path     = each.value.input_path

  dynamic "input_transformer" {
    for_each = each.value.input_transformer == null ? [] : [each.value.input_transformer]
    content {
      input_paths    = input_transformer.value.input_paths
      input_template = input_transformer.value.input_template
    }
  }

  dynamic "dead_letter_config" {
    for_each = each.value.dead_letter_arn == null ? [] : [each.value.dead_letter_arn]
    content {
      arn = dead_letter_config.value
    }
  }

  dynamic "retry_policy" {
    for_each = each.value.max_event_age == null && each.value.max_retry_attempts == null ? [] : [1]
    content {
      maximum_event_age_in_seconds = each.value.max_event_age
      maximum_retry_attempts       = each.value.max_retry_attempts
    }
  }
}
