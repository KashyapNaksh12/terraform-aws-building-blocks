# config

AWS Config recorder for all resource types, delivery to an encrypted S3 bucket, and a set of AWS managed rules for the usual SOC2 controls: CloudTrail, GuardDuty and Security Hub on, root MFA, IAM password policy and access key age, S3 public access and encryption, EBS/RDS encryption, IMDSv2, open SSH, VPC flow logs, RDS backups, DynamoDB PITR and more. The full list is in [rules.tf](rules.tf).

## Usage

```hcl
module "config" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/config?ref=v1.4.0"

  name        = "prod"
  kms_key_arn = module.kms.key_arn
}
```

Config is regional. In every other region you use, turn off global resources so IAM isn't recorded and checked twice:

```hcl
module "config_eu" {
  source    = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/config?ref=v1.4.0"
  providers = { aws = aws.eu_west_1 }

  name                     = "prod"
  include_global_resources = false
  s3_bucket_name           = module.config.bucket_name
  role_arn                 = module.config.role_arn
}
```

Skip rules that don't apply with `rules_disabled`, and add others with `rules`:

```hcl
rules_disabled = ["alb-http-to-https"]

rules = {
  eks-secrets-encrypted = { identifier = "EKS_SECRETS_ENCRYPTED" }
  acm-expiry = {
    identifier       = "ACM_CERTIFICATE_EXPIRATION_CHECK"
    input_parameters = { daysToExpiration = "30" }
  }
}
```

An account only has one recorder per region. If Config was already turned on by hand, import the recorder and delivery channel or delete them first.

Rules are billed per evaluation, and CONTINUOUS recording per configuration item. In accounts with a lot of churn (autoscaling, short-lived ECS tasks) `recording_frequency = "DAILY"` costs less.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name for the recorder, delivery channel, role and rule prefix | `string` | `"default"` | no |
| `role_arn` | Existing IAM role for Config. Null creates one with AWS_ConfigRole and write access to the bucket | `string` | `null` | no |
| `include_global_resources` | Record IAM and other global resources and run the IAM rules. Turn on in one region only | `bool` | `true` | no |
| `recording_frequency` | CONTINUOUS or DAILY | `string` | `"CONTINUOUS"` | no |
| `snapshot_frequency` | How often Config delivers a configuration snapshot: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours | `string` | `"TwentyFour_Hours"` | no |
| `s3_bucket_name` | Existing bucket for Config history and snapshots. Null creates one. The policy of an existing bucket is up to you | `string` | `null` | no |
| `bucket_name` | Name for the bucket this module creates. Defaults to <name>-config-<account id> | `string` | `null` | no |
| `s3_key_prefix` | Prefix for objects in the bucket | `string` | `null` | no |
| `force_destroy` | Let Terraform delete the bucket with objects in it | `bool` | `false` | no |
| `log_retention_days` | Delete objects from the bucket after this many days. Null keeps them forever | `number` | `2555` | no |
| `kms_key_arn` | KMS key for the bucket and delivered objects. The key policy must let the Config role use it | `string` | `null` | no |
| `sns_topic_arn` | SNS topic for configuration and compliance change notifications | `string` | `null` | no |
| `default_rules_enabled` | Create the built-in set of SOC2-related managed rules (see rules.tf) | `bool` | `true` | no |
| `rules_disabled` | Keys of default rules to skip, e.g. ["alb-http-to-https"] | `list(string)` | `[]` | no |
| `rules` | Extra AWS managed rules keyed by a static name. identifier is the managed rule ID, e.g. EKS_SECRETS_ENCRYPTED (identifier, input_parameters, resource_types) | `map(object)` | `{}` | no |
| `conformance_packs` | Conformance packs keyed by pack name, from a template body or S3 URI (template_body, template_s3_uri) | `map(object)` | `{}` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `recorder_name` | Name of the configuration recorder |
| `role_arn` | IAM role Config uses |
| `bucket_name` | Bucket Config delivers to |
| `bucket_arn` | ARN of the Config bucket |
| `rule_arns` | Config rule ARNs keyed by rule key |
<!-- END_TF_DOCS -->
