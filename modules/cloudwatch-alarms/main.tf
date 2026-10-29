locals {
  defaults = {
    statistic           = "Average"
    extended_statistic  = null
    comparison_operator = "GreaterThanThreshold"
    period              = 300
    evaluation_periods  = 3
    datapoints_to_alarm = null
    treat_missing_data  = "notBreaching"
  }

  rds = merge([
    for k, v in var.rds : {
      "rds-${k}-cpu" = merge(local.defaults, {
        description = "RDS ${v.instance_id} CPU above ${v.cpu_threshold}%"
        namespace   = "AWS/RDS"
        metric_name = "CPUUtilization"
        dimensions  = { DBInstanceIdentifier = v.instance_id }
        threshold   = v.cpu_threshold
      })
      "rds-${k}-free-storage" = merge(local.defaults, {
        description         = "RDS ${v.instance_id} free storage below ${v.free_storage_gb} GB"
        namespace           = "AWS/RDS"
        metric_name         = "FreeStorageSpace"
        statistic           = "Minimum"
        comparison_operator = "LessThanThreshold"
        dimensions          = { DBInstanceIdentifier = v.instance_id }
        threshold           = v.free_storage_gb * 1024 * 1024 * 1024
      })
      "rds-${k}-freeable-memory" = merge(local.defaults, {
        description         = "RDS ${v.instance_id} freeable memory below ${v.freeable_memory_mb} MB"
        namespace           = "AWS/RDS"
        metric_name         = "FreeableMemory"
        statistic           = "Minimum"
        comparison_operator = "LessThanThreshold"
        dimensions          = { DBInstanceIdentifier = v.instance_id }
        threshold           = v.freeable_memory_mb * 1024 * 1024
      })
    }
  ]...)

  # CloudWatch wants the ARN suffix: app/name/id and targetgroup/name/id
  alb = merge([
    for k, v in var.alb : merge(
      {
        "alb-${k}-elb-5xx" = merge(local.defaults, {
          description        = "ALB ${k} returned more than ${v.elb_5xx_threshold} 5xx itself in 5 minutes"
          namespace          = "AWS/ApplicationELB"
          metric_name        = "HTTPCode_ELB_5XX_Count"
          statistic          = "Sum"
          evaluation_periods = 1
          dimensions         = { LoadBalancer = split("loadbalancer/", v.lb_arn)[1] }
          threshold          = v.elb_5xx_threshold
        })
        "alb-${k}-target-5xx" = merge(local.defaults, {
          description        = "Targets behind ALB ${k} returned more than ${v.target_5xx_threshold} 5xx in 5 minutes"
          namespace          = "AWS/ApplicationELB"
          metric_name        = "HTTPCode_Target_5XX_Count"
          statistic          = "Sum"
          evaluation_periods = 1
          dimensions         = { LoadBalancer = split("loadbalancer/", v.lb_arn)[1] }
          threshold          = v.target_5xx_threshold
        })
        "alb-${k}-response-time" = merge(local.defaults, {
          description        = "ALB ${k} p95 response time above ${v.response_time_seconds}s"
          namespace          = "AWS/ApplicationELB"
          metric_name        = "TargetResponseTime"
          statistic          = null
          extended_statistic = "p95"
          dimensions         = { LoadBalancer = split("loadbalancer/", v.lb_arn)[1] }
          threshold          = v.response_time_seconds
        })
      },
      v.target_group_arn == null ? {} : {
        "alb-${k}-unhealthy-hosts" = merge(local.defaults, {
          description        = "ALB ${k} has unhealthy targets"
          namespace          = "AWS/ApplicationELB"
          metric_name        = "UnHealthyHostCount"
          statistic          = "Maximum"
          period             = 60
          evaluation_periods = 3
          dimensions = {
            LoadBalancer = split("loadbalancer/", v.lb_arn)[1]
            TargetGroup  = "targetgroup/${split(":targetgroup/", v.target_group_arn)[1]}"
          }
          threshold = 0
        })
      }
    )
  ]...)

  ecs = merge([
    for k, v in var.ecs : {
      "ecs-${k}-cpu" = merge(local.defaults, {
        description = "ECS ${v.service_name} CPU above ${v.cpu_threshold}%"
        namespace   = "AWS/ECS"
        metric_name = "CPUUtilization"
        dimensions  = { ClusterName = v.cluster_name, ServiceName = v.service_name }
        threshold   = v.cpu_threshold
      })
      "ecs-${k}-memory" = merge(local.defaults, {
        description = "ECS ${v.service_name} memory above ${v.memory_threshold}%"
        namespace   = "AWS/ECS"
        metric_name = "MemoryUtilization"
        dimensions  = { ClusterName = v.cluster_name, ServiceName = v.service_name }
        threshold   = v.memory_threshold
      })
    }
  ]...)

  lambda = merge([
    for k, v in var.lambda : {
      "lambda-${k}-errors" = merge(local.defaults, {
        description        = "Lambda ${v.function_name} had more than ${v.errors_threshold} errors in 5 minutes"
        namespace          = "AWS/Lambda"
        metric_name        = "Errors"
        statistic          = "Sum"
        evaluation_periods = 1
        dimensions         = { FunctionName = v.function_name }
        threshold          = v.errors_threshold
      })
      "lambda-${k}-throttles" = merge(local.defaults, {
        description        = "Lambda ${v.function_name} is being throttled"
        namespace          = "AWS/Lambda"
        metric_name        = "Throttles"
        statistic          = "Sum"
        evaluation_periods = 1
        dimensions         = { FunctionName = v.function_name }
        threshold          = v.throttles_threshold
      })
    }
  ]...)

  sqs = merge([
    for k, v in var.sqs : merge(
      {
        "sqs-${k}-oldest-message" = merge(local.defaults, {
          description = "SQS ${v.queue_name} oldest message older than ${v.max_age_seconds}s, consumers are behind"
          namespace   = "AWS/SQS"
          metric_name = "ApproximateAgeOfOldestMessage"
          statistic   = "Maximum"
          dimensions  = { QueueName = v.queue_name }
          threshold   = v.max_age_seconds
        })
      },
      v.dlq_name == null ? {} : {
        "sqs-${k}-dlq-messages" = merge(local.defaults, {
          description        = "SQS DLQ ${v.dlq_name} has messages"
          namespace          = "AWS/SQS"
          metric_name        = "ApproximateNumberOfMessagesVisible"
          statistic          = "Maximum"
          evaluation_periods = 1
          dimensions         = { QueueName = v.dlq_name }
          threshold          = 0
        })
      }
    )
  ]...)

  custom = {
    for k, v in var.alarms : k => {
      description         = v.description
      namespace           = v.namespace
      metric_name         = v.metric_name
      statistic           = v.extended_statistic == null ? v.statistic : null
      extended_statistic  = v.extended_statistic
      comparison_operator = v.comparison_operator
      period              = v.period
      evaluation_periods  = v.evaluation_periods
      datapoints_to_alarm = v.datapoints_to_alarm
      treat_missing_data  = v.treat_missing_data
      dimensions          = v.dimensions
      threshold           = v.threshold
    }
  }

  all = merge(local.rds, local.alb, local.ecs, local.lambda, local.sqs, local.custom)
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.all

  alarm_name          = "${var.name_prefix}-${each.key}"
  alarm_description   = each.value.description
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  dimensions          = each.value.dimensions
  statistic           = each.value.statistic
  extended_statistic  = each.value.extended_statistic
  comparison_operator = each.value.comparison_operator
  threshold           = each.value.threshold
  period              = each.value.period
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm
  treat_missing_data  = each.value.treat_missing_data

  alarm_actions             = var.alarm_actions
  ok_actions                = var.send_ok ? var.alarm_actions : []
  insufficient_data_actions = []

  tags = var.tags
}
