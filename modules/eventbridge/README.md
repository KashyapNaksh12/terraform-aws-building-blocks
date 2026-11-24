# eventbridge

EventBridge custom event bus with named event or schedule rules and optional targets. Target ARNs and permissions are supplied by the caller; grant EventBridge permission to invoke the selected target where required.

## Usage

```hcl
module "app_events" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/eventbridge?ref=v1.5.0"

  name = "app-events"
  rules = {
    order_created = {
      event_pattern = jsonencode({
        source        = ["my-app.orders"]
        "detail-type" = ["OrderCreated"]
      })
      targets = {
        queue = {
          arn = module.orders_queue.queue_arn
        }
      }
    }
    nightly = {
      schedule_expression = "cron(0 2 * * ? *)"
      targets = {
        worker = {
          arn      = module.worker.function_arn
          role_arn = aws_iam_role.events_invoke_worker.arn
        }
      }
    }
  }
}
```

Rules support event patterns or schedules. Targets support an IAM role, static input, input path or transformer, a dead-letter queue, and retry settings.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the EventBridge bus | `string` | n/a | yes |
| `description` | Description of the event bus | `string` | `null` | no |
| `rules` | Rules keyed by stable names; each can define an event pattern or schedule and targets | `map(object)` | `{}` | no |
| `tags` | Tags applied to the event bus | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `event_bus_name` | Name of the event bus |
| `event_bus_arn` | ARN of the event bus |
| `rule_arns` | ARNs of the created rules, keyed by rule name |
