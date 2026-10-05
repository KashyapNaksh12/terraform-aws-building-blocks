# iam-role

IAM role that can be trusted by AWS services, other accounts/roles, or GitHub Actions through OIDC. Can create the GitHub OIDC provider too, but remember only one is allowed per account.

## Usage

```hcl
# deploy role for github actions
module "github_deploy" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/iam-role?ref=v1.0.0"

  name                        = "github-deploy"
  create_github_oidc_provider = true
  github_oidc_subjects = [
    "repo:my-org/my-repo:ref:refs/heads/main",
    "repo:my-org/my-repo:environment:prod",
  ]

  managed_policy_arns = {
    power_user = "arn:aws:iam::aws:policy/PowerUserAccess"
  }
}

# role for an ECS task
module "ecs_task_role" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/iam-role?ref=v1.0.0"

  name             = "app-task"
  trusted_services = ["ecs-tasks.amazonaws.com"]
  inline_policies  = { s3 = data.aws_iam_policy_document.s3.json }
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the IAM role | `string` | n/a | **yes** |
| `description` | Description of the IAM role | `string` | `"Managed by Terraform"` | no |
| `path` | IAM path for the role | `string` | `"/"` | no |
| `max_session_duration` | Maximum session duration in seconds (3600-43200) | `number` | `3600` | no |
| `permissions_boundary_arn` | ARN of a permissions boundary policy | `string` | `null` | no |
| `assume_role_policy` | Custom trust policy JSON. Overrides trusted_* and github_oidc_* | `string` | `null` | no |
| `trusted_services` | Service principals that can assume the role, e.g. lambda.amazonaws.com | `list(string)` | `[]` | no |
| `trusted_role_arns` | IAM principal ARNs (accounts, roles, users) allowed to assume the role | `list(string)` | `[]` | no |
| `github_oidc_provider_arn` | Existing GitHub OIDC provider ARN | `string` | `null` | no |
| `github_oidc_subjects` | GitHub OIDC sub claims to allow, e.g. repo:my-org/my-repo:ref:refs/heads/main | `list(string)` | `[]` | no |
| `create_github_oidc_provider` | Create the GitHub OIDC provider. Only one can exist per account | `bool` | `false` | no |
| `managed_policy_arns` | Managed policies to attach, as name => arn | `map(string)` | `{}` | no |
| `inline_policies` | Inline policy JSON documents, keyed by policy name | `map(string)` | `{}` | no |
| `create_instance_profile` | Also create an EC2 instance profile for this role | `bool` | `false` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `role_name` | Name of the IAM role |
| `role_arn` | ARN of the IAM role |
| `role_unique_id` | Stable unique ID of the IAM role |
| `instance_profile_name` | Name of the instance profile (null if not created) |
| `github_oidc_provider_arn` | ARN of the GitHub OIDC provider used by the role (null if unused) |
<!-- END_TF_DOCS -->
