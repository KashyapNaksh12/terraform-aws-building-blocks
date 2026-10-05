# ecr

ECR repo with scan on push and immutable tags. The lifecycle policy expires untagged images after a week and keeps the last 30 by default.

## Usage

```hcl
module "ecr" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/ecr?ref=v1.0.0"

  name                   = "my-app"
  max_image_count        = 50
  read_access_arns       = ["arn:aws:iam::111111111111:root"]       # other account can pull
  read_write_access_arns = [module.github_deploy.role_arn]           # CI can push
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the ECR repository | `string` | n/a | **yes** |
| `image_tag_mutability` | MUTABLE or IMMUTABLE. IMMUTABLE prevents overwriting existing tags | `string` | `"IMMUTABLE"` | no |
| `scan_on_push` | Scan images for vulnerabilities on push | `bool` | `true` | no |
| `kms_key_arn` | KMS key ARN for encryption. Null uses AES256 | `string` | `null` | no |
| `force_delete` | Delete the repository even if it contains images | `bool` | `false` | no |
| `max_image_count` | Keep only this many tagged images (lifecycle policy). 0 disables the rule | `number` | `30` | no |
| `untagged_image_expiry_days` | Expire untagged images after this many days. 0 disables the rule | `number` | `7` | no |
| `read_access_arns` | IAM principal ARNs (e.g. other accounts) allowed to pull images | `list(string)` | `[]` | no |
| `read_write_access_arns` | IAM principal ARNs allowed to push and pull images (e.g. a CI role) | `list(string)` | `[]` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `repository_name` | Name of the repository |
| `repository_arn` | ARN of the repository |
| `repository_url` | URL of the repository (use as the image name for docker push) |
| `registry_id` | Registry (account) ID the repository lives in |
<!-- END_TF_DOCS -->
