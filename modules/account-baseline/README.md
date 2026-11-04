# account-baseline

Account-level security settings that SOC2 and CIS checks look for:

- IAM password policy (14+ characters, all character types, last 24 can't be reused, 90 day max age)
- S3 Block Public Access for the whole account
- EBS encryption by default, optionally with your own KMS key
- Public sharing of AMIs blocked, EC2 serial console off
- IAM Access Analyzer for resources shared outside the account, and optionally one for unused roles, users and permissions
- Optional account alias, alternate security/operations/billing contacts, and an `aws-support` role (MFA required)

## Usage

```hcl
module "account_baseline" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/account-baseline?ref=v1.4.0"

  account_alias = "acme-prod"

  alternate_contacts = {
    SECURITY = {
      name  = "Security Team"
      title = "Security"
      email = "security@example.com"
      phone = "+1-555-0100"
    }
  }

  support_role_principals = {
    ops = "arn:aws:iam::111122223333:role/ops"
  }

  access_analyzer = {
    name              = "prod"
    unused_access_age = 90
  }
}
```

EBS encryption, AMI blocking, the serial console and Access Analyzer are regional. The other settings are global to the account. For more regions, use the module again with `manage_global_settings = false`:

```hcl
module "account_baseline_eu" {
  source    = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/account-baseline?ref=v1.4.0"
  providers = { aws = aws.eu_west_1 }

  manage_global_settings = false
}
```

Set `password_policy.max_age_days = null` if you follow NIST 800-63B, which advises against forced rotation. The Config `iam-password-policy` rule checks for 90 days, so turn that off too.

Some things can't be done with Terraform and need to be done by hand: MFA on the root user, deleting root access keys, and turning on IAM access to billing.

The unused access analyzer is billed per IAM role and user it checks.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `manage_global_settings` | Create the account-wide settings (password policy, S3 public access block, alias, contacts, support role). Set false when using the module in a second region | `bool` | `true` | no |
| `password_policy` | IAM password policy. Upper, lower, numbers and symbols are always required. max_age_days null means passwords don't expire. Null skips the policy (minimum_length, reuse_prevention, max_age_days) | `object` | 14 chars, 24 reuse, 90 day max age | no |
| `s3_block_public_access` | Turn on S3 Block Public Access for the whole account | `bool` | `true` | no |
| `account_alias` | IAM account alias for the sign-in URL | `string` | `null` | no |
| `alternate_contacts` | Alternate contacts keyed by type: SECURITY, OPERATIONS or BILLING (name, title, email, phone) | `map(object)` | `{}` | no |
| `support_role_principals` | IAM principals that can assume an aws-support role (AWSSupportAccess, MFA required), keyed by a static name. Empty skips the role | `map(string)` | `{}` | no |
| `ebs_encryption_by_default` | Encrypt all new EBS volumes and snapshots in this region | `bool` | `true` | no |
| `ebs_kms_key_arn` | Default KMS key for EBS encryption in this region. Null uses aws/ebs | `string` | `null` | no |
| `block_public_amis` | Block public sharing of AMIs in this region | `bool` | `true` | no |
| `disable_serial_console` | Turn off EC2 serial console access in this region | `bool` | `true` | no |
| `access_analyzer` | IAM Access Analyzer for external access. unused_access_age (days) also creates an unused access analyzer, which is billed per role/user. Null skips it (name, organization, unused_access_age) | `object` | account analyzer named default | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `access_analyzer_arn` | ARN of the external access analyzer |
| `unused_access_analyzer_arn` | ARN of the unused access analyzer |
| `support_role_arn` | ARN of the aws-support role |
<!-- END_TF_DOCS -->
