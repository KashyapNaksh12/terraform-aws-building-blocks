# guardduty

GuardDuty detector with the protection plans you pick, optional export of findings to S3, and an EventBridge rule that sends findings above a severity to SNS.

## Usage

```hcl
module "guardduty" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/guardduty?ref=v1.4.0"

  name          = "prod"
  notifications = { sns_topic_arn = module.alerts.topic_arn }
}
```

By default S3, EKS audit logs, EBS malware scanning, RDS login and Lambda network protection are on. Runtime monitoring (EKS, ECS Fargate, EC2) is off because it deploys an agent, turn it on with:

```hcl
features = {
  S3_DATA_EVENTS         = true
  EKS_AUDIT_LOGS         = true
  EBS_MALWARE_PROTECTION = true
  RDS_LOGIN_EVENTS       = true
  LAMBDA_NETWORK_LOGS    = true
  RUNTIME_MONITORING     = true
}
```

Only high and critical findings (severity 7+) are sent by default, set `notifications.min_severity = 4` to include medium. The SNS topic must let `events.amazonaws.com` publish (`publisher_service_principals` on the sns module), and if the topic is encrypted the key must let EventBridge use it.

GuardDuty keeps findings for 90 days. To keep them longer for the audit, set `export_bucket_arn` and `export_kms_key_arn` (see the AWS docs for the bucket and key policy GuardDuty needs).

GuardDuty is regional, use the module in every region you run things in.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Prefix for the EventBridge rule | `string` | `"default"` | no |
| `finding_publishing_frequency` | How often updated findings are published: FIFTEEN_MINUTES, ONE_HOUR or SIX_HOURS | `string` | `"FIFTEEN_MINUTES"` | no |
| `features` | Protection plans to turn on or off. Each is billed separately | `map(bool)` | S3, EKS, EBS malware, RDS, Lambda on; runtime off | no |
| `runtime_monitoring_agents` | Agent management for runtime monitoring: EKS_ADDON_MANAGEMENT, ECS_FARGATE_AGENT_MANAGEMENT, EC2_AGENT_MANAGEMENT | `map(bool)` | all three on | no |
| `export_bucket_arn` | S3 bucket ARN to export findings to, for keeping them longer than 90 days. Bucket and key policies are up to you | `string` | `null` | no |
| `export_kms_key_arn` | KMS key for exported findings, required by GuardDuty when exporting | `string` | `null` | no |
| `notifications` | Send findings to an SNS topic (must allow events.amazonaws.com to publish). min_severity: 4 = medium, 7 = high, 9 = critical. Null turns it off (sns_topic_arn, min_severity) | `object` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `detector_id` | GuardDuty detector ID |
| `detector_arn` | GuardDuty detector ARN |
<!-- END_TF_DOCS -->
