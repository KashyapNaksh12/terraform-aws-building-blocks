# vpc-flow-logs

VPC flow logs to a CloudWatch log group, with the IAM role the flow log service needs. Used by [vpc](../vpc), also usable for a VPC created elsewhere.

## Usage

```hcl
module "flow_logs" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/vpc-flow-logs?ref=v1.5.0"

  name           = "prod"
  vpc_id         = module.vpc.vpc_id
  retention_days = 365
  kms_key_arn    = module.kms.key_arn
}
```

The KMS key policy must allow CloudWatch Logs (`allow_cloudwatch_logs` on the kms module).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name used for the log group and role prefix, usually the VPC name | `string` | n/a | **yes** |
| `vpc_id` | VPC to capture flow logs for | `string` | n/a | **yes** |
| `traffic_type` | Traffic type to capture: ACCEPT, REJECT, or ALL | `string` | `"ALL"` | no |
| `retention_days` | Retention in days for the flow logs log group | `number` | `30` | no |
| `kms_key_arn` | KMS key ARN for the flow logs log group. The key policy must allow CloudWatch Logs | `string` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `flow_log_id` | ID of the flow log |
| `log_group_name` | Name of the CloudWatch log group |
| `log_group_arn` | ARN of the CloudWatch log group |
<!-- END_TF_DOCS -->
