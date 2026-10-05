# dynamodb

DynamoDB table, on-demand by default, with PITR and deletion protection turned on. GSIs, TTL and streams are optional.

## Usage

```hcl
module "orders" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/dynamodb?ref=v1.0.0"

  name      = "orders"
  hash_key  = "pk"
  range_key = "sk"

  attributes = [
    { name = "pk", type = "S" },
    { name = "sk", type = "S" },
    { name = "customer_id", type = "S" },
  ]

  global_secondary_indexes = [
    { name = "by-customer", hash_key = "customer_id", range_key = "sk" },
  ]

  ttl_attribute    = "expires_at"
  stream_view_type = "NEW_AND_OLD_IMAGES"
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the DynamoDB table | `string` | n/a | **yes** |
| `hash_key` | Partition key attribute name | `string` | n/a | **yes** |
| `range_key` | Sort key attribute name (optional) | `string` | `null` | no |
| `attributes` | Key attributes for the table and its indexes (type S, N or B) | `list(object)` | n/a | **yes** |
| `billing_mode` | PAY_PER_REQUEST (on-demand) or PROVISIONED | `string` | `"PAY_PER_REQUEST"` | no |
| `read_capacity` | Read capacity units (PROVISIONED only) | `number` | `null` | no |
| `write_capacity` | Write capacity units (PROVISIONED only) | `number` | `null` | no |
| `global_secondary_indexes` | Global secondary indexes | `list(object)` | `[]` | no |
| `ttl_attribute` | Attribute name holding the expiry epoch for TTL. Null disables TTL | `string` | `null` | no |
| `point_in_time_recovery` | Enable point-in-time recovery (continuous backups) | `bool` | `true` | no |
| `kms_key_arn` | Customer-managed KMS key ARN. Null uses the AWS-owned key | `string` | `null` | no |
| `stream_view_type` | Stream view type, e.g. NEW_AND_OLD_IMAGES. Null = no stream | `string` | `null` | no |
| `deletion_protection` | Enable deletion protection | `bool` | `true` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `table_name` | Name of the table |
| `table_arn` | ARN of the table |
| `stream_arn` | ARN of the table stream (null if streams are disabled) |
<!-- END_TF_DOCS -->
