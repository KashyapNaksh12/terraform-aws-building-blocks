# backup

AWS Backup vault, plan and selection. Resources tagged `Backup = true` get daily backups kept for 35 days and monthly backups kept for a year. Failed backup, copy and restore jobs go to SNS.

## Usage

```hcl
module "backup" {
  source = "git::https://github.com/KashyapNaksh12/terraform-aws-building-blocks.git//modules/backup?ref=v1.4.0"

  name          = "prod"
  kms_key_arn   = module.kms.key_arn
  notifications = { sns_topic_arn = module.alerts.topic_arn }
}
```

Then tag what should be backed up (RDS, DynamoDB, EFS, EBS, EC2, S3...):

```hcl
tags = { Backup = "true" }
```

Copies to another region for disaster recovery:

```hcl
rules = {
  daily = {
    schedule     = "cron(0 3 * * ? *)"
    delete_after = 35
    copy_to = {
      dr = { vault_arn = module.backup_dr.vault_arn }
    }
  }
}
```

Vault Lock stops anyone, including root, from deleting recovery points before `min_retention_days`:

```hcl
vault_lock = {
  min_retention_days  = 7
  max_retention_days  = 400
  changeable_for_days = 3
}
```

Careful: with `changeable_for_days` set, the lock is in compliance mode and can't be changed or removed once those days have passed, and the vault can't be deleted until every recovery point has expired. Leave `changeable_for_days` out for governance mode, which users with the right IAM permissions can still remove.

S3 backups need versioning on the bucket. Restores should be tested now and then, SOC2 auditors usually ask for evidence of a restore test.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name for the vault, plan, selection and role | `string` | n/a | **yes** |
| `kms_key_arn` | KMS key for the vault. Null uses the AWS managed backup key | `string` | `null` | no |
| `force_destroy` | Let Terraform delete the vault with recovery points in it. Doesn't work once a vault lock is active | `bool` | `false` | no |
| `vault_lock` | Vault Lock. With changeable_for_days set it becomes COMPLIANCE mode and can't be removed after that many days (min 3). Null means no lock (min_retention_days, max_retention_days, changeable_for_days) | `object` | `null` | no |
| `rules` | Backup rules keyed by rule name. schedule is a cron() expression, delete_after in days. copy_to sends copies to another vault (other region/account) for DR (schedule, timezone, start_window, completion_window, delete_after, cold_storage_after, continuous_backup, copy_to) | `map(object)` | daily (35 days), monthly (365 days, cold after 30) | no |
| `windows_vss` | Take application-consistent (VSS) backups of Windows EC2 instances | `bool` | `false` | no |
| `role_arn` | Existing IAM role for AWS Backup. Null creates one with the AWS managed backup/restore policies | `string` | `null` | no |
| `selection_tag` | Back up resources with this tag. Set to null to only use resource_arns (key, value) | `object` | `{ key = "Backup", value = "true" }` | no |
| `resource_arns` | Resources to back up, keyed by a static name. Combined with selection_tag both have to match | `map(string)` | `{}` | no |
| `notifications` | Send failed backup, copy and restore jobs to an SNS topic (must allow events.amazonaws.com to publish). Null turns it off (sns_topic_arn) | `object` | `null` | no |
| `tags` | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vault_name` | Name of the backup vault |
| `vault_arn` | ARN of the backup vault |
| `plan_id` | ID of the backup plan |
| `plan_arn` | ARN of the backup plan |
| `role_arn` | IAM role AWS Backup uses |
<!-- END_TF_DOCS -->
