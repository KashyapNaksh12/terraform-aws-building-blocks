# security-hub

Security Hub with consolidated control findings, the AWS Foundational Security Best Practices and CIS 3.0 standards, documented control exceptions, optional cross-region aggregation, and new high/critical findings sent to SNS.

## Usage

```hcl
module "security_hub" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/security-hub?ref=v1.4.0"

  name          = "prod"
  notifications = { sns_topic_arn = module.alerts.topic_arn }

  disabled_controls = {
    hardware-mfa = {
      standard   = "aws-foundational-security-best-practices/v/1.0.0"
      control_id = "IAM.6"
      reason     = "Root uses a virtual MFA device, accepted by security team"
    }
  }
}
```

Most controls are Config rules under the hood, so turn on the config module first.

Other standards go in `standards` by the path after `standards/` in their ARN, e.g. `nist-800-53/v/5.0.0` or `pci-dss/v/4.0.1`. The old CIS 1.2.0 standard uses a different ARN format and isn't supported here, use 3.0.0.

The reason on a disabled control shows up in the console and the API, which gives the auditor a record of why it was accepted.

To see findings from all regions in one place, set `aggregate_regions = []` in the main region (Security Hub still has to be enabled in each region).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Prefix for the EventBridge rule | `string` | `"default"` | no |
| `standards` | Standards to subscribe to, as the part after standards/ in the ARN, e.g. nist-800-53/v/5.0.0 or pci-dss/v/4.0.1 | `list(string)` | FSBP 1.0.0, CIS 3.0.0 | no |
| `disabled_controls` | Controls to turn off, keyed by a static name. standard must be in var.standards, control_id is e.g. EC2.10, reason is shown in the console (standard, control_id, reason) | `map(object)` | `{}` | no |
| `aggregate_regions` | Make this region the aggregation region. [] links all regions, a list links only those. Null turns aggregation off | `list(string)` | `null` | no |
| `notifications` | Send new findings to an SNS topic (must allow events.amazonaws.com to publish). Null turns it off (sns_topic_arn, severities) | `object` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `hub_arn` | ARN of the Security Hub |
| `standards_subscription_arns` | Standards subscription ARNs keyed by standard |
<!-- END_TF_DOCS -->
