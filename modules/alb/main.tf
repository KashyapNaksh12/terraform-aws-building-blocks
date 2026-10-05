locals {
  https_enabled = var.certificate_arn != null
  listen_ports  = local.https_enabled ? [80, 443] : [80]
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-alb-"
  description = "ALB ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-alb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = {
    for pair in setproduct(local.listen_ports, var.allowed_cidrs) :
    "${pair[0]}-${pair[1]}" => { port = pair[0], cidr = pair[1] }
  }

  security_group_id = aws_security_group.this.id
  description       = "Listener ${each.value.port}"
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound to targets"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lb" "this" {
  name                       = var.name
  load_balancer_type         = "application"
  internal                   = var.internal
  subnets                    = var.subnet_ids
  security_groups            = concat([aws_security_group.this.id], var.additional_security_group_ids)
  idle_timeout               = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != null ? [1] : []

    content {
      bucket  = var.access_logs_bucket
      prefix  = var.name
      enabled = true
    }
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_lb_target_group" "this" {
  name_prefix = substr(replace(var.name, "-", ""), 0, 6)
  vpc_id      = var.target_type == "lambda" ? null : var.vpc_id
  target_type = var.target_type
  port        = var.target_type == "lambda" ? null : var.target_port
  protocol    = var.target_type == "lambda" ? null : var.target_protocol

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check.path
    matcher             = var.health_check.matcher
    interval            = var.health_check.interval
    timeout             = var.health_check.timeout
    healthy_threshold   = var.health_check.healthy_threshold
    unhealthy_threshold = var.health_check.unhealthy_threshold
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = var.target_ids

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = each.value
  port             = var.target_type == "lambda" ? null : var.target_port
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = local.https_enabled ? [1] : []

    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = local.https_enabled ? [] : [1]

    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }

  tags = var.tags
}

resource "aws_lb_listener" "https" {
  count = local.https_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = var.tags
}
