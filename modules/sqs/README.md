# sqs

SQS queue with a dead-letter queue, encryption (SQS-managed or KMS) and a queue policy that denies non-TLS access. Standard or FIFO.

## Usage

```hcl
module "jobs" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/sqs?ref=v1.2.0"

  name                       = "prod-jobs"
  visibility_timeout_seconds = 180 # 6x the consumer Lambda timeout
  max_receive_count          = 3
  kms_key_arn                = module.kms.key_arn
}
```

Subscribed to an SNS topic:

```hcl
module "orders_queue" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/sqs?ref=v1.2.0"

  name           = "prod-orders"
  sns_topic_arns = { orders = module.orders_topic.topic_arn }
}
```

With a KMS key, the key policy has to let the producers use it. For SNS, add `sns = "sns.amazonaws.com"` to `service_principals` in the kms module.

FIFO names get `.fifo` added, so `name = "orders"` with `fifo_queue = true` gives `orders.fifo` and `orders-dlq.fifo`.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Queue name. .fifo is added for FIFO queues, the DLQ gets -dlq | `string` | n/a | yes |
| `fifo_queue` | Create a FIFO queue (and FIFO DLQ) | `bool` | `false` | no |
| `content_based_deduplication` | FIFO only, deduplicate on a hash of the message body | `bool` | `false` | no |
| `deduplication_scope` | FIFO only, messageGroup or queue | `string` | `"queue"` | no |
| `fifo_throughput_limit` | FIFO only, perQueue or perMessageGroupId (high throughput mode) | `string` | `"perQueue"` | no |
| `visibility_timeout_seconds` | Visibility timeout. Set it to at least 6x the Lambda timeout when a Lambda consumes the queue | `number` | `30` | no |
| `message_retention_seconds` | How long messages are kept (60-1209600) | `number` | `345600` | no |
| `max_message_size` | Max message size in bytes (1024-262144) | `number` | `262144` | no |
| `delay_seconds` | Delay before new messages become visible (0-900) | `number` | `0` | no |
| `receive_wait_time_seconds` | Long polling wait time (0-20) | `number` | `20` | no |
| `create_dlq` | Create a dead-letter queue and redrive to it | `bool` | `true` | no |
| `max_receive_count` | Receives before a message is moved to the DLQ | `number` | `5` | no |
| `dlq_message_retention_seconds` | How long messages are kept in the DLQ | `number` | `1209600` | no |
| `kms_key_arn` | KMS key for encryption. Null uses SQS-managed SSE | `string` | `null` | no |
| `kms_data_key_reuse_period_seconds` | How long SQS reuses a data key before calling KMS again (60-86400) | `number` | `300` | no |
| `sns_topic_arns` | SNS topics allowed to send to the queue, keyed by a static name | `map(string)` | `{}` | no |
| `policy` | Extra queue policy JSON, merged with the generated statements | `string` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `queue_url` | URL of the queue |
| `queue_arn` | ARN of the queue |
| `queue_name` | Name of the queue |
| `dlq_url` | URL of the DLQ (null if create_dlq is false) |
| `dlq_arn` | ARN of the DLQ (null if create_dlq is false) |
<!-- END_TF_DOCS -->
