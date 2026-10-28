locals {
  create_zone = var.zone_id == null
  zone_id     = local.create_zone ? aws_route53_zone.this[0].zone_id : var.zone_id
}

resource "aws_route53_zone" "this" {
  count = local.create_zone ? 1 : 0

  name              = var.domain_name
  comment           = var.comment
  force_destroy     = var.force_destroy
  delegation_set_id = length(var.vpc_ids) == 0 ? var.delegation_set_id : null

  # private zone when VPCs are given
  dynamic "vpc" {
    for_each = var.vpc_ids

    content {
      vpc_id = vpc.value
    }
  }

  tags = merge(var.tags, { Name = var.domain_name })

  lifecycle {
    precondition {
      condition     = var.domain_name != null
      error_message = "Set domain_name to create a zone, or zone_id to use an existing one."
    }
  }
}

resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = local.zone_id
  # "" or "@" means the apex
  name            = contains(["", "@"], each.value.name) ? data.aws_route53_zone.this.name : each.value.name
  type            = each.value.type
  ttl             = each.value.alias == null ? each.value.ttl : null
  records         = each.value.alias == null ? each.value.records : null
  set_identifier  = each.value.set_identifier
  health_check_id = each.value.health_check_id
  allow_overwrite = each.value.allow_overwrite

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []

    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  dynamic "weighted_routing_policy" {
    for_each = each.value.weight != null ? [each.value.weight] : []

    content {
      weight = weighted_routing_policy.value
    }
  }

  dynamic "failover_routing_policy" {
    for_each = each.value.failover != null ? [each.value.failover] : []

    content {
      type = failover_routing_policy.value
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.alias != null || length(each.value.records) > 0
      error_message = "Record ${each.key} needs either records or alias."
    }
  }
}

# zone name with the trailing dot stripped, works for both created and existing zones
data "aws_route53_zone" "this" {
  zone_id = local.zone_id
}
