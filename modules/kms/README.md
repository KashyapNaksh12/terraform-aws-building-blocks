# kms

Customer-managed KMS key with an alias and automatic rotation. The key policy always gives the account root full access so IAM policies keep working and you can't lock yourself out. On top of that you can add key admins, key users, CloudWatch Logs and other AWS services.

## Usage

```hcl
module "kms" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/kms?ref=v1.0.0"

  alias       = "app-prod"
  description = "app prod data"

  admin_arns = {
    platform = "arn:aws:iam::111122223333:role/platform-admin"
  }

  user_arns = {
    app = module.app.task_role_arn
  }

  # needed if log groups (lambda, ecs-fargate, vpc flow logs) use this key
  allow_cloudwatch_logs = true

  service_principals = {
    sns = "sns.amazonaws.com"
  }
}
```

Then pass `module.kms.key_arn` to the other modules, e.g. `kms_key_arn` on s3, dynamodb, ecr, lambda and secrets-manager, `kms_key_id` on rds and ec2, and `log_kms_key_arn` / `flow_logs_kms_key_arn` for log groups.

The policy is set with a separate `aws_kms_key_policy` resource, because the CloudWatch Logs statement needs the region and that comes from the key ARN. User principals also get `kms:CreateGrant` when `kms:GrantIsForAWSResource` is true, which services like RDS and EBS need.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `alias` | Alias for the key, with or without the alias/ prefix | `string` | n/a | **yes** |
| `description` | Description of the key | `string` | `"Managed by Terraform"` | no |
| `key_usage` | ENCRYPT_DECRYPT, SIGN_VERIFY or GENERATE_VERIFY_MAC | `string` | `"ENCRYPT_DECRYPT"` | no |
| `key_spec` | Key spec, e.g. SYMMETRIC_DEFAULT, RSA_2048, ECC_NIST_P256. Rotation only works on SYMMETRIC_DEFAULT | `string` | `"SYMMETRIC_DEFAULT"` | no |
| `multi_region` | Create a multi-Region primary key | `bool` | `false` | no |
| `enable_key_rotation` | Rotate the key material automatically (symmetric keys only) | `bool` | `true` | no |
| `rotation_period_in_days` | Days between automatic rotations (90-2560) | `number` | `365` | no |
| `deletion_window_in_days` | Waiting period before the key is deleted (7-30) | `number` | `30` | no |
| `admin_arns` | IAM principals that can manage the key (not use it), keyed by a static name | `map(string)` | `{}` | no |
| `user_arns` | IAM principals that can encrypt/decrypt with the key and create grants for AWS services, keyed by a static name | `map(string)` | `{}` | no |
| `allow_cloudwatch_logs` | Let CloudWatch Logs in this account and region use the key, needed for encrypted log groups | `bool` | `false` | no |
| `service_principals` | AWS service principals that can use the key directly, e.g. { sns = "sns.amazonaws.com" }. Limited to this account via aws:SourceAccount | `map(string)` | `{}` | no |
| `policy` | Extra key policy JSON, merged with the generated statements | `string` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `key_id` | ID of the key |
| `key_arn` | ARN of the key |
| `alias_name` | Alias name, including the alias/ prefix |
| `alias_arn` | ARN of the alias |
<!-- END_TF_DOCS -->
