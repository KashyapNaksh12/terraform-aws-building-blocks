# sns

SNS topic with a policy that keeps it to the owner account and denies non-TLS publishes, optional KMS encryption, AWS service publishers and subscriptions.

## Usage

Alerts topic for CloudWatch alarms, emailed to the on-call list:

```hcl
module "alerts" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/sns?ref=v1.2.0"

  name                         = "prod-alerts"
  publisher_service_principals = { cw = "cloudwatch.amazonaws.com" }

  subscriptions = {
    oncall = {
      protocol = "email"
      endpoint = "oncall@example.com"
    }
  }
}
```

Fan-out to SQS with a filter:

```hcl
module "orders_topic" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/sns?ref=v1.2.0"

  name        = "prod-orders"
  kms_key_arn = module.kms.key_arn

  subscriptions = {
    billing = {
      protocol             = "sqs"
      endpoint             = module.billing_queue.queue_arn
      raw_message_delivery = true
      filter_policy        = jsonencode({ event = ["order_paid"] })
    }
  }
}
```

The queue also needs to allow the topic, see `sns_topic_arns` in the sqs module. Email subscriptions stay pending until someone clicks the confirmation link.

If you encrypt the topic, services that publish to it (CloudWatch, EventBridge) need `kms:GenerateDataKey` and `kms:Decrypt` on the key. Add them to `service_principals` in the kms module. The AWS-managed `alias/aws/sns` key doesn't allow that.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Topic name. .fifo is added for FIFO topics | `string` | n/a | yes |
| `display_name` | Display name, used as the sender for SMS and email | `string` | `null` | no |
| `fifo_topic` | Create a FIFO topic (only SQS FIFO queues can subscribe) | `bool` | `false` | no |
| `content_based_deduplication` | FIFO only, deduplicate on a hash of the message body | `bool` | `false` | no |
| `kms_key_arn` | KMS key for encryption. Null leaves the topic unencrypted | `string` | `null` | no |
| `delivery_policy` | Delivery retry policy JSON for HTTP/S endpoints | `string` | `null` | no |
| `publisher_service_principals` | AWS services allowed to publish, limited to this account via aws:SourceAccount | `map(string)` | `{}` | no |
| `policy` | Extra topic policy JSON, merged with the generated statements | `string` | `null` | no |
| `subscriptions` | Subscriptions keyed by a static name (protocol, endpoint, raw_message_delivery, filter_policy, filter_policy_scope, dlq_arn) | `map(object)` | `{}` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `topic_arn` | ARN of the topic |
| `topic_name` | Name of the topic |
| `subscription_arns` | Subscription ARNs keyed like var.subscriptions |
<!-- END_TF_DOCS -->
