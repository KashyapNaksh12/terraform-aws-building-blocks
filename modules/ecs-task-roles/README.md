# ecs-task-roles

The two IAM roles an ECS task needs. Used by [ecs-fargate](../ecs-fargate), also usable for EC2-backed services.

- **Execution role**: lets the ECS agent pull the image, write logs and read the secrets the container refers to (Secrets Manager and SSM parameters, plus `kms:Decrypt` on the keys you list)
- **Task role**: what the app itself can do. Attach managed policies, add an inline policy and optionally the SSM messages permissions for `aws ecs execute-command`

## Usage

```hcl
module "roles" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/ecs-task-roles?ref=v1.5.0"

  name = "api"

  secrets = {
    DB_PASSWORD = aws_secretsmanager_secret.db.arn
  }

  task_role_policy_arns  = { s3 = aws_iam_policy.uploads.arn }
  enable_execute_command = true
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the service, used as the prefix for the role names | `string` | n/a | **yes** |
| `secrets` | Secrets the container reads, env var name => Secrets Manager or SSM parameter ARN. The execution role gets read access to them | `map(string)` | `{}` | no |
| `secrets_kms_key_arns` | Customer-managed KMS keys the secrets are encrypted with, keyed by a static name. The execution role gets kms:Decrypt on them | `map(string)` | `{}` | no |
| `execution_role_policy_arns` | Extra managed policies for the execution role | `map(string)` | `{}` | no |
| `task_role_policy_arns` | Managed policies for the task role (the app's permissions), keyed by a static name | `map(string)` | `{}` | no |
| `task_role_inline_policy` | Inline policy JSON for the task role | `string` | `null` | no |
| `enable_execute_command` | Give the task role the SSM messages permissions `aws ecs execute-command` needs | `bool` | `false` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `execution_role_arn` | ARN of the task execution role |
| `execution_role_name` | Name of the task execution role |
| `task_role_arn` | ARN of the task role (the app's permissions) |
| `task_role_name` | Name of the task role |
<!-- END_TF_DOCS -->
