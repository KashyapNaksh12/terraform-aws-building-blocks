# secrets-manager

Secrets Manager secret. By default it's created empty so the value never touches Terraform state, and you fill it with the CLI or console. You can also set the value from Terraform, turn on rotation with a Lambda, replicate to other regions and attach a resource policy.

## Usage

Empty secret, value set outside Terraform:

```hcl
module "api_key" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/secrets-manager?ref=v1.0.0"

  name        = "prod/app/stripe-api-key"
  kms_key_arn = module.kms.key_arn
}
```

```bash
aws secretsmanager put-secret-value --secret-id prod/app/stripe-api-key --secret-string '...'
```

Value from Terraform, only set once and then left to rotation:

```hcl
module "db_creds" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/secrets-manager?ref=v1.0.0"

  name        = "prod/app/db"
  kms_key_arn = module.kms.key_arn

  create_value         = true
  secret_string        = jsonencode({ username = "app", password = var.db_password })
  ignore_value_changes = true

  rotation_lambda_arn = module.rotator.function_arn
  rotation_days       = 30
}
```

To use it in ecs-fargate, pass `module.db_creds.secret_arn` in `container.secrets` and the KMS key in `secrets_kms_key_arns`.

When `create_value` is true the value ends up in state, so keep the state encrypted and access-limited.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the secret. Mutually exclusive with name_prefix | `string` | `null` | no |
| `name_prefix` | Name prefix, AWS adds a unique suffix. Mutually exclusive with name | `string` | `null` | no |
| `description` | Description of the secret | `string` | `"Managed by Terraform"` | no |
| `kms_key_arn` | Customer-managed KMS key ARN. Null uses the AWS-managed aws/secretsmanager key | `string` | `null` | no |
| `recovery_window_in_days` | Days before a deleted secret is gone for good (7-30), or 0 to delete immediately | `number` | `30` | no |
| `create_value` | Create a secret version from secret_string. False leaves the secret empty for someone else to fill | `bool` | `false` | no |
| `secret_string` | Secret value, plain text or jsonencode(...). Ends up in state | `string` | `null` | no |
| `ignore_value_changes` | Only set the value on create and ignore later changes (for rotated or app-managed values) | `bool` | `false` | no |
| `rotation_lambda_arn` | Lambda that rotates the secret. Null disables rotation | `string` | `null` | no |
| `rotation_days` | Rotate every N days (used when rotation_schedule_expression is null) | `number` | `30` | no |
| `rotation_schedule_expression` | rate() or cron() expression for rotation, overrides rotation_days | `string` | `null` | no |
| `replica_regions` | Regions to replicate the secret to, region => KMS key ARN (null for the AWS-managed key there) | `map(string)` | `{}` | no |
| `policy` | Resource policy JSON for the secret (e.g. cross-account read) | `string` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `secret_id` | ID of the secret (same as the ARN) |
| `secret_arn` | ARN of the secret |
| `secret_name` | Name of the secret |
| `version_id` | ID of the version created by this module (null if create_value is false) |
<!-- END_TF_DOCS -->
