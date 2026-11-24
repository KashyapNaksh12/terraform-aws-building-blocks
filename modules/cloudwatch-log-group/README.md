# cloudwatch-log-group

CloudWatch log group with configurable retention, optional KMS encryption, and a destroy protection option.

## Usage

```hcl
module "app_logs" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/cloudwatch-log-group?ref=v1.5.0"

  name              = "/my-app/worker"
  retention_in_days = 90
  kms_key_id        = module.logs_key.key_arn
  tags              = { Environment = "production" }
}
```

Set `retention_in_days = null` to retain events indefinitely. `skip_destroy = true` keeps the log group when the module is destroyed.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Log group name, commonly prefixed with /aws/ | `string` | n/a | yes |
| `retention_in_days` | Number of days to retain events. Null keeps events indefinitely | `number` | `30` | no |
| `kms_key_id` | ARN of a KMS key used to encrypt log data | `string` | `null` | no |
| `skip_destroy` | Retain the log group when Terraform destroys it | `bool` | `false` | no |
| `tags` | Tags applied to the log group | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `name` | Name of the log group |
| `arn` | ARN of the log group |
| `arn_prefix` | ARN of the log group without the trailing `:*` |
