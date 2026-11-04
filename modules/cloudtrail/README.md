# cloudtrail

Multi-region CloudTrail with log file validation, an encrypted and locked-down S3 bucket, a CloudWatch log group and the CIS "monitoring" alarms (root usage, console login without MFA, IAM / security group / NACL / route / VPC changes, CloudTrail and Config being tampered with, KMS keys being disabled, and so on).

## Usage

```hcl
module "cloudtrail" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/cloudtrail?ref=v1.4.0"

  name          = "prod"
  kms_key_arn   = module.kms.key_arn
  alarm_actions = [module.alerts.topic_arn]
}
```

The KMS key needs CloudTrail and CloudWatch Logs in its policy. With the kms module:

```hcl
module "kms" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/kms?ref=v1.4.0"

  alias                 = "audit"
  allow_cloudwatch_logs = true
  service_principals    = { cloudtrail = "cloudtrail.amazonaws.com" }
}
```

What you get by default:

- Management events from every region, global service events, digest files for log file validation
- A bucket named `<name>-cloudtrail-<account id>` with versioning, SSE (KMS when `kms_key_arn` is set), Block Public Access, TLS-only, and a policy that only lets this trail write and denies deleting log objects. Logs go to Glacier after 90 days and expire after 7 years
- A log group `/aws/cloudtrail/<name>` (365 days) with 15 metric filters and alarms. Turn single ones off with `security_alarms_disabled`, keys are in [alarms.tf](alarms.tf)

For evidence the logs can't be changed, set `object_lock = { mode = "COMPLIANCE", days = 365 }`. Object Lock can only be turned on when the bucket is created. With `deny_log_deletion = true` (the default) nobody can delete log objects by hand, so `terraform destroy` fails on a bucket with logs in it. Set it to false together with `force_destroy` for test accounts.

For an organization trail, create it in the management account with `is_organization_trail = true` and `organization_id`.

To use a central log bucket instead, pass `s3_bucket_name`. That bucket's policy has to allow this trail.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Trail name, also used for the bucket, log group and alarm names | `string` | n/a | **yes** |
| `kms_key_arn` | KMS key for the trail, bucket and log group. The key policy must allow cloudtrail.amazonaws.com and CloudWatch Logs (allow_cloudwatch_logs on the kms module) | `string` | `null` | no |
| `is_multi_region_trail` | Log events from all regions | `bool` | `true` | no |
| `is_organization_trail` | Trail for every account in the organization. Must be created in the management (or delegated admin) account | `bool` | `false` | no |
| `organization_id` | Organization ID (o-xxxx), lets an organization trail write to the bucket | `string` | `null` | no |
| `s3_bucket_name` | Existing bucket to send logs to. Null creates a bucket in this module. The bucket policy of an existing bucket is up to you | `string` | `null` | no |
| `bucket_name` | Name for the bucket this module creates. Defaults to <name>-cloudtrail-<account id> | `string` | `null` | no |
| `s3_key_prefix` | Prefix for log objects in the bucket | `string` | `null` | no |
| `force_destroy` | Let Terraform delete the bucket with logs in it. Needs deny_log_deletion = false | `bool` | `false` | no |
| `deny_log_deletion` | Bucket policy denies deleting log objects for everyone. Lifecycle expiry is not affected | `bool` | `true` | no |
| `object_lock` | Turn on S3 Object Lock with a default retention (mode GOVERNANCE or COMPLIANCE). Only works on a new bucket (mode, days) | `object` | `null` | no |
| `glacier_transition_days` | Move logs to Glacier after this many days. Null keeps them in Standard | `number` | `90` | no |
| `log_retention_days` | Delete logs from the bucket after this many days. Null keeps them forever. SOC2 auditors usually want at least 365 | `number` | `2555` | no |
| `access_logging_bucket` | Bucket for S3 server access logs of the trail bucket. Null turns access logging off | `string` | `null` | no |
| `cloudwatch_logs_enabled` | Also send the trail to a CloudWatch log group. Needed for the security alarms | `bool` | `true` | no |
| `cloudwatch_logs_retention_days` | Retention for the CloudWatch log group | `number` | `365` | no |
| `sns_topic_arn` | SNS topic to notify on every log file delivery. Usually not needed | `string` | `null` | no |
| `s3_data_events` | Log S3 object-level events (GetObject, PutObject...) for all buckets. Can get expensive | `bool` | `false` | no |
| `lambda_data_events` | Log Lambda Invoke events for all functions | `bool` | `false` | no |
| `insight_types` | CloudTrail Insights types: ApiCallRateInsight, ApiErrorRateInsight. Extra cost | `list(string)` | `[]` | no |
| `security_alarms_enabled` | Create the CIS metric filters and alarms (root usage, console login without MFA, IAM/SG/NACL/VPC changes...) | `bool` | `true` | no |
| `security_alarms_disabled` | Alarm keys to skip, e.g. ["organizations-changes"]. See alarms.tf for the list | `list(string)` | `[]` | no |
| `alarm_actions` | ARNs to notify when a security alarm fires, usually an SNS topic | `list(string)` | `[]` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `trail_arn` | ARN of the trail |
| `trail_name` | Name of the trail |
| `bucket_name` | Bucket the logs go to |
| `bucket_arn` | ARN of the log bucket |
| `log_group_name` | CloudWatch log group of the trail, null if cloudwatch_logs_enabled = false |
| `log_group_arn` | ARN of the CloudWatch log group |
| `alarm_arns` | Security alarm ARNs keyed by alarm key |
<!-- END_TF_DOCS -->
