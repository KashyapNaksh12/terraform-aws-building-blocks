# inspector

Turns on Amazon Inspector vulnerability scanning for EC2 instances, ECR images and Lambda functions in this account and region, and sends new high/critical findings to SNS.

## Usage

```hcl
module "inspector" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/inspector?ref=v1.4.0"

  name          = "prod"
  notifications = { sns_topic_arn = module.alerts.topic_arn }
}
```

EC2 scanning uses the SSM agent, so instances need to be managed by SSM (the ec2 module does that). ECR enhanced scanning replaces basic scanning on the registry. `LAMBDA_CODE` adds code scanning of Lambda functions for an extra cost.

Inspector findings also show up in Security Hub.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Prefix for the EventBridge rule | `string` | `"default"` | no |
| `resource_types` | What to scan: EC2, ECR, LAMBDA, LAMBDA_CODE | `list(string)` | `["EC2", "ECR", "LAMBDA"]` | no |
| `notifications` | Send new findings to an SNS topic (must allow events.amazonaws.com to publish). Null turns it off (sns_topic_arn, severities) | `object` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `resource_types` | Resource types Inspector scans |
<!-- END_TF_DOCS -->
