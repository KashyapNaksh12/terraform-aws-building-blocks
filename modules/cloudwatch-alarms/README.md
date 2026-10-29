# cloudwatch-alarms

CloudWatch metric alarms with sensible defaults for the things the other modules create (RDS, ALB, ECS, Lambda, SQS), plus any custom alarm. Everything notifies the same actions, usually the topic from the sns module.

## Usage

```hcl
module "alerts" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/sns?ref=v1.3.0"

  name                         = "prod-alerts"
  publisher_service_principals = { cw = "cloudwatch.amazonaws.com" }
  subscriptions = {
    oncall = { protocol = "email", endpoint = "oncall@example.com" }
  }
}

module "alarms" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/cloudwatch-alarms?ref=v1.3.0"

  name_prefix   = "prod"
  alarm_actions = [module.alerts.topic_arn]

  rds = {
    main = { instance_id = module.db.db_instance_id }
  }

  alb = {
    web = {
      lb_arn           = module.alb.lb_arn
      target_group_arn = module.alb.target_group_arn
    }
  }

  ecs = {
    api = {
      cluster_name = module.api.cluster_name
      service_name = module.api.service_name
    }
  }

  lambda = {
    worker = { function_name = module.worker.function_name }
  }

  sqs = {
    jobs = {
      queue_name = module.jobs.queue_name
      dlq_name   = "prod-jobs-dlq"
    }
  }

  alarms = {
    ec2-disk = {
      namespace   = "CWAgent"
      metric_name = "disk_used_percent"
      dimensions  = { InstanceId = module.web.instance_id, path = "/" }
      threshold   = 85
    }
  }
}
```

Alarm names are `<name_prefix>-<key>`, e.g. `prod-rds-main-cpu`. The keys are listed in the `alarm_arns` output.

What the presets create:

| Preset | Alarms | Default threshold |
|--------|--------|-------------------|
| `rds` | CPU, free storage, freeable memory | 80%, 5 GB, 256 MB |
| `alb` | ELB 5xx, target 5xx, p95 response time, unhealthy hosts (when `target_group_arn` is set) | 10 / 5 min, 10 / 5 min, 1s, any |
| `ecs` | CPU, memory | 85%, 85% |
| `lambda` | errors, throttles | any |
| `sqs` | age of oldest message, messages in the DLQ (when `dlq_name` is set) | 15 min, any |

Thresholds can be changed per resource. Missing data counts as OK, so quiet resources don't alarm.

If the SNS topic is encrypted with a customer-managed key, the key policy has to allow `cloudwatch.amazonaws.com` (add it to `service_principals` in the kms module), otherwise the alarms fire but nothing gets delivered.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name_prefix` | Prefix for alarm names, e.g. prod | `string` | n/a | yes |
| `alarm_actions` | ARNs to notify when an alarm fires, usually an SNS topic | `list(string)` | `[]` | no |
| `send_ok` | Also notify alarm_actions when an alarm goes back to OK | `bool` | `true` | no |
| `rds` | RDS instances to watch, keyed by a static name (instance_id, cpu_threshold, free_storage_gb, freeable_memory_mb) | `map(object)` | `{}` | no |
| `alb` | ALBs to watch, keyed by a static name (lb_arn, target_group_arn, elb_5xx_threshold, target_5xx_threshold, response_time_seconds) | `map(object)` | `{}` | no |
| `ecs` | ECS services to watch, keyed by a static name (cluster_name, service_name, cpu_threshold, memory_threshold) | `map(object)` | `{}` | no |
| `lambda` | Lambda functions to watch, keyed by a static name (function_name, errors_threshold, throttles_threshold) | `map(object)` | `{}` | no |
| `sqs` | SQS queues to watch, keyed by a static name (queue_name, dlq_name, max_age_seconds) | `map(object)` | `{}` | no |
| `alarms` | Any other metric alarms, keyed by a static name (namespace, metric_name, dimensions, statistic, extended_statistic, comparison_operator, threshold, period, evaluation_periods, datapoints_to_alarm, treat_missing_data) | `map(object)` | `{}` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `alarm_arns` | Alarm ARNs keyed by alarm key, e.g. rds-main-cpu |
| `alarm_names` | Alarm names keyed by alarm key |
<!-- END_TF_DOCS -->
